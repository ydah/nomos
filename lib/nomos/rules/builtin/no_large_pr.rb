# frozen_string_literal: true

require_relative "../base"
require_relative "../../finding"

module Nomos
  module Rules
    module Builtin
      class NoLargePr < Base
        def run(context)
          max = params.fetch(:max_changed_lines, 0)
          return [] if max <= 0

          return [] if context.changed_lines <= max

          message = [
            "PR size exceeds limit",
            "- Reason: #{context.changed_lines} lines changed (max #{max}).",
            "- Impact: Large PRs are harder to review and riskier to merge.",
            "- Action: Split this PR or raise the limit."
          ].join("\n")

          [Finding.fail(message, source: name)]
        end
      end
    end
  end
end
