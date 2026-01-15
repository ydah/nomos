# frozen_string_literal: true

require_relative "nomos/version"
require_relative "nomos/cli"
require_relative "nomos/cache"
require_relative "nomos/config"
require_relative "nomos/context"
require_relative "nomos/context_loader"
require_relative "nomos/finding"
require_relative "nomos/github_client"
require_relative "nomos/rules"
require_relative "nomos/rules/ruby_file"
require_relative "nomos/runner"
require_relative "nomos/reporters/console"
require_relative "nomos/reporters/github"
require_relative "nomos/reporters/json"
require_relative "nomos/timing"

module Nomos
  class Error < StandardError; end
end
