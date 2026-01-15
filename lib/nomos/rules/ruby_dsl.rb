# frozen_string_literal: true

require_relative "../finding"

module Nomos
  module Rules
    module RubyDSL
      class RuleContext
        def initialize(context, rule_name)
          @context = context
          @rule_name = rule_name
          @findings = []
        end

        def changed_files
          @context.changed_files
        end

        def diff(file)
          @context.diff(file).to_s
        end

        def pr_title
          @context.pull_request["title"]
        end

        def pr_body
          @context.pull_request["body"]
        end

        def pr_number
          @context.pull_request["number"]
        end

        def pr_author
          @context.pull_request.dig("user", "login")
        end

        def pr_labels
          Array(@context.pull_request["labels"]).map { |label| label["name"] }.compact
        end

        def repo
          @context.repo
        end

        def base_branch
          @context.base_branch
        end

        def ci
          @context.ci
        end

        def message(text, **opts)
          @findings << Finding.message(text, **opts, source: @rule_name)
        end

        def warn(text, **opts)
          @findings << Finding.warn(text, **opts, source: @rule_name)
        end

        def fail(text, **opts)
          @findings << Finding.fail(text, **opts, source: @rule_name)
        end

        def findings
          @findings.dup
        end
      end

      class RuleDefinition
        def initialize(name, block)
          @name = name
          @block = block
        end

        def run(context)
          rule_context = RuleContext.new(context, @name)
          rule_context.instance_eval(&@block)
          rule_context.findings
        end
      end

      class RuleSet
        def initialize
          @rules = []
        end

        def rule(name, &block)
          raise ArgumentError, "Rule name is required" if name.to_s.empty?

          @rules << RuleDefinition.new(name, block)
        end

        def run(context)
          @rules.flat_map { |rule| rule.run(context) }
        end
      end
    end
  end
end
