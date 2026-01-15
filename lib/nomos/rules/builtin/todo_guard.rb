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

          [Finding.fail("TODO found in diffs: #{matches.join(", ")}", source: name)]
        end
      end
    end
  end
end
