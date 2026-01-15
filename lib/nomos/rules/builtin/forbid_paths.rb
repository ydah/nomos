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

          [Finding.fail("Forbidden paths changed: #{matches.join(", ")}", source: name)]
        end
      end
    end
  end
end
