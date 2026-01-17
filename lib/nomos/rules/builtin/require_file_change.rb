# frozen_string_literal: true

require_relative "../base"
require_relative "../../finding"

module Nomos
  module Rules
    module Builtin
      class RequireFileChange < Base
        def run(context)
          patterns = Array(params[:patterns])
          return [] if patterns.empty?

          matched = patterns.any? do |pattern|
            context.changed_files.any? { |file| File.fnmatch?(pattern, file) }
          end

          return [] if matched

          message = [
            "Required file update missing",
            "- Reason: None of these patterns were changed: #{patterns.join(", ")}.",
            "- Action: Update at least one matching file or adjust the rule."
          ].join("\n")

          [Finding.fail(message, source: name)]
        end
      end
    end
  end
end
