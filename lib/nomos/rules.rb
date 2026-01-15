# frozen_string_literal: true

require_relative "rules/base"
require_relative "rules/builtin/no_large_pr"
require_relative "rules/builtin/require_file_change"
require_relative "rules/builtin/forbid_paths"
require_relative "rules/builtin/require_labels"
require_relative "rules/builtin/todo_guard"
require_relative "rules/ruby_file"

module Nomos
  module Rules
    BUILTIN_MAP = {
      "builtin.no_large_pr" => Builtin::NoLargePr,
      "builtin.require_file_change" => Builtin::RequireFileChange,
      "builtin.forbid_paths" => Builtin::ForbidPaths,
      "builtin.require_labels" => Builtin::RequireLabels,
      "builtin.todo_guard" => Builtin::TodoGuard,
      "ruby.file" => RubyFile
    }.freeze

    def self.build(rule_config)
      name = rule_config.fetch(:name)
      type = rule_config.fetch(:type)
      params = rule_config.fetch(:params, {})

      klass = BUILTIN_MAP[type]
      raise Nomos::Error, "Unknown rule type: #{type}" unless klass

      klass.new(name: name, params: params)
    end
  end
end
