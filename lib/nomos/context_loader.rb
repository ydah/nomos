# frozen_string_literal: true

require "json"

require_relative "cache"
require_relative "context"
require_relative "github_client"

module Nomos
  class ContextLoader
    def self.load(env: ENV, performance: {})
      event = read_event(env["GITHUB_EVENT_PATH"])
      pr_number = event.dig("pull_request", "number") || event["number"] || env["NOMOS_PR_NUMBER"]
      repo = env["GITHUB_REPOSITORY"] || env["NOMOS_REPOSITORY"]

      unless pr_number && repo
        raise Nomos::Error, "Missing PR context. Set GITHUB_EVENT_PATH/GITHUB_REPOSITORY or NOMOS_PR_NUMBER/NOMOS_REPOSITORY."
      end

      token = env["GITHUB_TOKEN"]
      api_url = env["GITHUB_API_URL"] || "https://api.github.com"

      client = GitHubClient.new(token: token, api_url: api_url)

      cache_enabled = performance.fetch(:cache, false)
      cache_path = performance.fetch(:cache_path, ".nomos/cache.json")
      cache = Cache.new(path: cache_path, enabled: cache_enabled)

      pr_cache_key = "pr:#{repo}##{pr_number}"
      files_cache_key = "files:#{repo}##{pr_number}"

      pr = cache.fetch(pr_cache_key) { client.pull_request(repo, pr_number) }
      files = cache.fetch(files_cache_key) { client.pull_request_files(repo, pr_number) }

      changed_files = files.map { |file| file.fetch("filename") }
      lazy_diff = performance.fetch(:lazy_diff, false)
      patches = lazy_diff ? {} : files.each_with_object({}) { |file, memo| memo[file["filename"]] = file["patch"] }
      patch_fetcher = lazy_diff ? lambda { |filename| files.find { |file| file["filename"] == filename }&.fetch("patch", nil) } : nil
      changed_lines = files.sum { |file| file.fetch("additions", 0) + file.fetch("deletions", 0) }

      Context.new(
        pull_request: pr,
        changed_files: changed_files,
        patches: patches,
        patch_fetcher: patch_fetcher,
        repo: repo,
        base_branch: pr.dig("base", "ref"),
        ci: {
          "workflow" => env["GITHUB_WORKFLOW"],
          "run_id" => env["GITHUB_RUN_ID"],
          "actor" => env["GITHUB_ACTOR"]
        },
        changed_lines: changed_lines
      )
    end

    def self.read_event(path)
      return {} unless path && File.exist?(path)

      JSON.parse(File.read(path))
    rescue JSON::ParserError => e
      raise Nomos::Error, "Invalid event JSON at #{path}: #{e.message}"
    end
    private_class_method :read_event
  end
end
