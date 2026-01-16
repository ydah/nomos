# frozen_string_literal: true

RSpec.describe Nomos::Reporters::GitHub do
  let(:client) { instance_double(Nomos::GitHubClient) }
  let(:repo) { "owner/repo" }
  let(:pr_number) { 99 }

  it "formats findings with file and line" do
    allow(client).to receive(:list_issue_comments).and_return([])
    allow(client).to receive(:pull_request_files).and_return([])

    expect(client).to receive(:create_comment) do |_, _, body|
      expect(body).to include("## Nomos Report")
      expect(body).to include("**WARN**")
      expect(body).to include("`lib/example.rb:12`")
    end

    reporter = described_class.new(client: client, repo: repo, pr_number: pr_number)
    finding = Nomos::Finding.warn("Check", file: "lib/example.rb", line: 12, source: "spec")

    reporter.report([finding])
  end

  it "renders empty report" do
    allow(client).to receive(:list_issue_comments).and_return([])
    allow(client).to receive(:pull_request_files).and_return([])

    expect(client).to receive(:create_comment) do |_, _, body|
      expect(body).to include("No issues found.")
    end

    reporter = described_class.new(client: client, repo: repo, pr_number: pr_number)
    reporter.report([])
  end
end
