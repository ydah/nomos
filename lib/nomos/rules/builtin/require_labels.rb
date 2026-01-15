# frozen_string_literal: true

require_relative "../base"
require_relative "../../finding"

module Nomos
  module Rules
    module Builtin
      class RequireLabels < Base
        def run(context)
          required = Array(params[:labels]).map(&:to_s).reject(&:empty?)
          return [] if required.empty?

          labels = Array(context.pull_request["labels"]).map { |label| label["name"] }.compact
          missing = required - labels

          return [] if missing.empty?

          [Finding.fail("Missing required labels: #{missing.join(", ")}", source: name)]
        end
      end
    end
  end
end
