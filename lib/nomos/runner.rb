# frozen_string_literal: true

require_relative "finding"
require_relative "rules"

module Nomos
  class Runner
    def initialize(config, context)
      @config = config
      @context = context
    end

    def run
      rules = @config.rules.map { |rule_config| Rules.build(rule_config) }
      return [] if rules.empty?

      concurrency = @config.performance.fetch(:concurrency, 1).to_i
      return run_sequential(rules) if concurrency <= 1 || rules.length == 1

      run_parallel(rules, concurrency)
    end

    private

    def run_sequential(rules)
      findings = []

      rules.each do |rule|
        begin
          findings.concat(Array(rule.run(@context)))
        rescue StandardError => e
          findings << Finding.fail("Rule #{rule.name} failed: #{e.message}", source: rule.name)
        end
      end

      findings
    end

    def run_parallel(rules, concurrency)
      queue = Queue.new
      rules.each { |rule| queue << rule }

      findings = []
      mutex = Mutex.new
      threads = Array.new([concurrency, rules.length].min) do
        Thread.new do
          loop do
            rule = queue.pop(true)
            begin
              result = Array(rule.run(@context))
              mutex.synchronize { findings.concat(result) }
            rescue StandardError => e
              mutex.synchronize do
                findings << Finding.fail("Rule #{rule.name} failed: #{e.message}", source: rule.name)
              end
            end
          end
        rescue ThreadError
          # queue empty
        end
      end

      threads.each(&:join)
      findings
    end
  end
end
