# frozen_string_literal: true

require_relative "base"
require_relative "ruby_dsl"

module Nomos
  module Rules
    class RubyFile < Base
      def run(context)
        path = params.fetch(:path)
        raise Nomos::Error, "Rule file not found: #{path}" unless File.exist?(path)

        ruleset = RubyDSL::RuleSet.new
        ruleset.instance_eval(File.read(path), path)
        ruleset.run(context)
      end
    end
  end
end
