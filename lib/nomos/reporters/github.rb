# frozen_string_literal: true

require "set"

module Nomos
  module Reporters
    class GitHub
      MARKER = "<!-- nomos:report -->"
      INLINE_MARKER = "<!-- nomos:inline -->"
      INLINE_SEVERITIES = %i[warn fail].freeze

      def initialize(client:, repo:, pr_number:, pull_request: nil, context: nil)
        @client = client
        @repo = repo
        @pr_number = pr_number
        @pull_request = pull_request
        @context = context
      end

      def report(findings)
        body = build_body(findings)
        existing = find_existing_comment

        if existing
          @client.update_comment(@repo, existing.fetch("id"), body)
        else
          @client.create_comment(@repo, @pr_number, body)
        end

        create_inline_comments(findings)
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

      def create_inline_comments(findings)
        inline_findings = findings.select { |finding| INLINE_SEVERITIES.include?(finding.severity) }
        return if inline_findings.empty?

        comments = inline_findings.filter_map do |finding|
          next unless finding.file && finding.line

          diff_lines = diff_lines_for(finding.file)
          next unless diff_lines.include?(finding.line)

          {
            path: finding.file,
            line: finding.line,
            side: "RIGHT",
            body: build_inline_body(finding)
          }
        end

        return if comments.empty?

        pr = @pull_request || @context&.pull_request || @client.pull_request(@repo, @pr_number)
        commit_id = pr.dig("head", "sha")

        @client.create_review(
          @repo,
          @pr_number,
          body: "Nomos inline review comments",
          event: "COMMENT",
          comments: comments,
          commit_id: commit_id
        )
      rescue Nomos::Error => e
        warn "Nomos inline review comment failed: #{e.message}"
      end

      def build_inline_body(finding)
        label = finding.severity.to_s.upcase
        source = finding.source.to_s.empty? ? "" : " (#{finding.source})"
        "#{INLINE_MARKER}\n**#{label}** #{finding.text}#{source}"
      end

      def diff_lines_for(file)
        @diff_lines_by_file ||= {}
        return @diff_lines_by_file[file] if @diff_lines_by_file.key?(file)

        patch = patch_for(file)
        @diff_lines_by_file[file] = right_side_lines(patch)
      end

      def patch_for(file)
        return @context.diff(file) if @context

        @pr_files ||= @client.pull_request_files(@repo, @pr_number)
        @pr_files.find { |entry| entry["filename"] == file }&.fetch("patch", nil)
      end

      def right_side_lines(patch)
        return Set.new unless patch

        lines = Set.new
        right_line = nil

        patch.each_line do |line|
          if line.start_with?("@@")
            match = line.match(/\@\@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? \@\@/)
            right_line = match ? match[1].to_i : nil
            next
          end

          next unless right_line

          case line[0]
          when "+"
            next if line.start_with?("+++")
            lines << right_line
            right_line += 1
          when "-"
            next if line.start_with?("---")
          when " "
            lines << right_line
            right_line += 1
          when "\\"
            # no newline at end of file; ignore
          end
        end

        lines
      end
    end
  end
end
