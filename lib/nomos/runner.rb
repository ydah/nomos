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
      findings = []

      @config.rules.each do |rule_config|
        rule = Rules.build(rule_config)
        begin
          findings.concat(Array(rule.run(@context)))
        rescue StandardError => e
          findings << Finding.fail("Rule #{rule.name} failed: #{e.message}", source: rule.name)
        end
      end

      findings
    end
  end
end
