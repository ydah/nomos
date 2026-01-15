# frozen_string_literal: true

require "optparse"

require_relative "config"
require_relative "context_loader"
require_relative "github_client"
require_relative "runner"
require_relative "reporters/console"
require_relative "reporters/github"
require_relative "timing"

module Nomos
  class CLI
    def self.run(argv)
      command = argv.shift || "run"

      case command
      when "run"
        new.run(argv)
      when "init"
        new.init(argv)
      when "doctor"
        new.doctor(argv)
      else
        warn "Unknown command: #{command}"
        1
      end
    end

    def run(argv)
      options = {
        config: Config::DEFAULT_PATH,
        strict: false,
        debug: false,
        reporter: nil
      }

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: nomos run [options]"
        opts.on("--config PATH", "Config path (default: nomos.yml)") { |path| options[:config] = path }
        opts.on("--strict", "Treat warns as failures") { options[:strict] = true }
        opts.on("--debug", "Show debug details") { options[:debug] = true }
        opts.on("--reporter LIST", "Comma-separated reporters (github,console,json)") do |list|
          options[:reporter] = list.split(",").map(&:strip)
        end
      end

      parser.parse!(argv)

      timing = Timing.new
      config = timing.measure("config") { Config.load(options[:config]) }
      context = timing.measure("context") { ContextLoader.load(performance: config.performance) }
      findings = timing.measure("rules") { Runner.new(config, context).run }

      reporters = timing.measure("reporters") { build_reporters(config, context, options[:reporter]) }
      timing.measure("report_outputs") { reporters.each { |reporter| reporter.report(findings) } }

      timing.report if config.performance.fetch(:timing, false)

      exit_code(findings, options[:strict])
    rescue Nomos::Error => e
      warn e.message
      raise if options[:debug]

      1
    end

    def init(_argv)
      config_path = Config::DEFAULT_PATH
      rules_path = ".nomos/rules.rb"

      if File.exist?(config_path)
        warn "#{config_path} already exists"
      else
        File.write(config_path, default_config)
        puts "Created #{config_path}"
      end

      unless File.exist?(File.dirname(rules_path))
        Dir.mkdir(File.dirname(rules_path))
      end

      if File.exist?(rules_path)
        warn "#{rules_path} already exists"
      else
        File.write(rules_path, default_rules)
        puts "Created #{rules_path}"
      end

      0
    end

    def doctor(_argv)
      config_path = Config::DEFAULT_PATH
      ok = true

      unless File.exist?(config_path)
        warn "Missing config: #{config_path}"
        ok = false
      end

      if ENV["GITHUB_TOKEN"].to_s.empty?
        warn "Missing GITHUB_TOKEN"
        ok = false
      end

      if ENV["GITHUB_EVENT_PATH"].to_s.empty? && (ENV["NOMOS_PR_NUMBER"].to_s.empty? || ENV["NOMOS_REPOSITORY"].to_s.empty?)
        warn "Missing PR context (GITHUB_EVENT_PATH or NOMOS_PR_NUMBER/NOMOS_REPOSITORY)"
        ok = false
      end

      puts ok ? "Nomos doctor: OK" : "Nomos doctor: issues found"
      ok ? 0 : 1
    end

    private

    def build_reporters(config, context, override)
      enabled = if override
                  override.map(&:downcase)
                else
                  config.reporters.map { |name, value| name.to_s if value }.compact
                end

      enabled = ["console"] if enabled.empty?

      enabled.map do |name|
        case name
        when "console"
          Reporters::Console.new
        when "github"
          client = GitHubClient.new(token: ENV["GITHUB_TOKEN"], api_url: ENV["GITHUB_API_URL"] || "https://api.github.com")
          Reporters::GitHub.new(client: client, repo: context.repo, pr_number: context.pull_request.fetch("number"))
        when "json"
          Reporters::Json.new(path: json_report_path(config))
        else
          raise Nomos::Error, "Unknown reporter: #{name}"
        end
      end
    end

    def exit_code(findings, strict)
      return 1 if findings.any? { |finding| finding.severity == :fail }
      return 1 if strict && findings.any? { |finding| finding.severity == :warn }

      0
    end

    def default_config
      <<~YAML
        version: 1

        reporter:
          github: true
          console: true
          json:
            path: nomos-report.json

        performance:
          concurrency: 4
          cache: true
          lazy_diff: true
          timing: false

        rules:
          - name: no_large_pr
            type: builtin.no_large_pr
            params:
              max_changed_lines: 800

          - name: require_changelog
            type: builtin.require_file_change
            params:
              patterns:
                - CHANGELOG.md
      YAML
    end

    def default_rules
      <<~RUBY
        # frozen_string_literal: true

        # Custom rules will be supported in Phase 2.
      RUBY
    end

    def json_report_path(config)
      json = config.reporters[:json]
      case json
      when Hash
        json[:path] || "nomos-report.json"
      when String
        json
      when true
        "nomos-report.json"
      else
        "nomos-report.json"
      end
    end
  end
end
