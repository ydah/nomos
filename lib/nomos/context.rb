# frozen_string_literal: true

module Nomos
  class Context
    attr_reader :pull_request, :changed_files, :patches, :repo, :base_branch, :ci, :changed_lines

    def initialize(pull_request:, changed_files:, patches:, repo:, base_branch:, ci:, changed_lines:)
      @pull_request = pull_request
      @changed_files = changed_files
      @patches = patches
      @repo = repo
      @base_branch = base_branch
      @ci = ci
      @changed_lines = changed_lines
      freeze
    end
  end
end
