# frozen_string_literal: true

require_relative "../base"
require_relative "../../finding"

module Nomos
  module Rules
    module Builtin
      class ForbidPaths < Base
        def run(context)
          patterns = Array(params[:patterns])
          return [] if patterns.empty?

          matches = context.changed_files.select do |file|
            patterns.any? { |pattern| File.fnmatch?(pattern, file) }
          end

          return [] if matches.empty?

          message = [
            "Restricted paths changed",
            "- Files: #{matches.join(", ")}",
            "- Impact: Changes in protected paths require extra review.",
            "- Action: Revert these changes or update the rule."
          ].join("\n")

          [Finding.fail(message, source: name)]
        end
      end
    end
  end
end
