# frozen_string_literal: true

module Nomos
  module Reporters
    class GitHub
      MARKER = "<!-- nomos:report -->"

      def initialize(client:, repo:, pr_number:)
        @client = client
        @repo = repo
        @pr_number = pr_number
      end

      def report(findings)
        body = build_body(findings)
        existing = find_existing_comment

        if existing
          @client.update_comment(@repo, existing.fetch("id"), body)
        else
          @client.create_comment(@repo, @pr_number, body)
        end
      end

      private

      def find_existing_comment
        comments = @client.list_issue_comments(@repo, @pr_number)
        comments.find { |comment| comment.fetch("body", "").include?(MARKER) }
      end

      def build_body(findings)
        lines = [MARKER, "## Nomos Report", ""]

        if findings.empty?
          lines << "No issues found."
        else
          findings.each do |finding|
            label = finding.severity.to_s.upcase
            location = if finding.file
                         " (`#{finding.file}#{finding.line ? ":#{finding.line}" : ""}`)"
                       else
                         ""
                       end
            lines << "- **#{label}** #{finding.text}#{location}"
          end
        end

        lines.join("\n")
      end
    end
  end
end
