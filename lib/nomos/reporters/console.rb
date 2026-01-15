# frozen_string_literal: true

module Nomos
  module Reporters
    class Console
      def report(findings)
        if findings.empty?
          puts "Nomos: no findings"
          return
        end

        findings.each do |finding|
          location = if finding.file
                       " (#{finding.file}#{finding.line ? ":#{finding.line}" : ""})"
                     else
                       ""
                     end

          puts "[#{finding.severity}] #{finding.text}#{location}"
        end
      end
    end
  end
end
