# frozen_string_literal: true

require_relative "../base"
require_relative "../../finding"

module Nomos
  module Rules
    module Builtin
      class TodoGuard < Base
        def run(context)
          patterns = Array(params[:patterns])
          patterns = ["TODO"] if patterns.empty?

          matches = context.changed_files.select do |file|
            diff = context.diff(file).to_s
            patterns.any? { |pattern| diff.include?(pattern) }
          end

          return [] if matches.empty?

          message = [
            "TODO markers in diff",
            "- Files: #{matches.join(", ")}",
            "- Action: Resolve or remove TODOs, or update the patterns."
          ].join("\n")

          [Finding.fail(message, source: name)]
        end
      end
    end
  end
end
