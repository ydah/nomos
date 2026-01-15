# frozen_string_literal: true

module Nomos
  class Context
    attr_reader :pull_request, :changed_files, :repo, :base_branch, :ci, :changed_lines

    def initialize(pull_request:, changed_files:, patches:, repo:, base_branch:, ci:, changed_lines:, patch_fetcher: nil)
      @pull_request = pull_request
      @changed_files = changed_files
      @patches = patches
      @patch_fetcher = patch_fetcher
      @repo = repo
      @base_branch = base_branch
      @ci = ci
      @changed_lines = changed_lines
      freeze
    end

    def diff(file)
      return @patches[file] if @patches.key?(file)
      return unless @patch_fetcher

      @patches[file] = @patch_fetcher.call(file)
    end
  end
end
