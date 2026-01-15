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

          [Finding.fail("Required files not changed: #{patterns.join(", ")}", source: name)]
        end
      end
    end
  end
end
