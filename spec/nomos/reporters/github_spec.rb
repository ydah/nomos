# frozen_string_literal: true

RSpec.describe Nomos::Reporters::GitHub do
  let(:client) { instance_double(Nomos::GitHubClient) }
  let(:repo) { "owner/repo" }
  let(:pr_number) { 42 }

  it "creates a comment when none exists" do
    allow(client).to receive(:list_issue_comments).and_return([])
    allow(client).to receive(:pull_request_files).and_return([])
    expect(client).to receive(:create_comment) do |_, _, body|
      expect(body).to include(Nomos::Reporters::GitHub::MARKER)
      expect(body).to include("Nomos Report")
    end

    reporter = described_class.new(client: client, repo: repo, pr_number: pr_number)
    reporter.report([])
  end

  it "updates existing comment with marker" do
    allow(client).to receive(:list_issue_comments).and_return([
      { "id" => 10, "body" => "#{Nomos::Reporters::GitHub::MARKER}\nold" }
    ])
    allow(client).to receive(:pull_request_files).and_return([])

    expect(client).to receive(:update_comment) do |_, id, body|
      expect(id).to eq(10)
      expect(body).to include("Nomos Report")
    end

    reporter = described_class.new(client: client, repo: repo, pr_number: pr_number)
    reporter.report([Nomos::Finding.warn("Warn", source: "spec")])
  end
end
