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

          [Finding.fail("PR is too large (#{context.changed_lines} lines changed, max #{max})", source: name)]
        end
      end
    end
  end
end
