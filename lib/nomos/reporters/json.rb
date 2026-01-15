# frozen_string_literal: true

require "json"
require "time"

module Nomos
  module Reporters
    class Json
      def initialize(path:)
        @path = path
      end

      def report(findings)
        data = {
          generated_at: Time.now.utc.iso8601,
          counts: count_findings(findings),
          findings: findings.map(&:to_h)
        }

        File.write(@path, JSON.pretty_generate(data))
      end

      private

      def count_findings(findings)
        counts = Hash.new(0)
        findings.each { |finding| counts[finding.severity] += 1 }
        counts
      end
    end
  end
end
