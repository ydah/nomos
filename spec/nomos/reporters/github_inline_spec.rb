# frozen_string_literal: true

RSpec.describe Nomos::Reporters::GitHub do
  let(:client) { instance_double(Nomos::GitHubClient) }
  let(:repo) { "owner/repo" }
  let(:pr_number) { 12 }

  it "creates inline review comments for warn and fail findings on diff lines" do
    allow(client).to receive(:list_issue_comments).and_return([])
    allow(client).to receive(:create_comment)

    patch = <<~PATCH
      @@ -1,1 +1,2 @@
       line
      +added
    PATCH

    context = instance_double(Nomos::Context)
    allow(context).to receive(:diff).with("lib/example.rb").and_return(patch)

    pull_request = { "head" => { "sha" => "abc123" }, "number" => pr_number }
    reporter = described_class.new(
      client: client,
      repo: repo,
      pr_number: pr_number,
      pull_request: pull_request,
      context: context
    )

    finding = Nomos::Finding.warn("Check", file: "lib/example.rb", line: 2, source: "spec")

    expect(client).to receive(:create_review) do |_, _, body:, event:, comments:, commit_id:|
      expect(body).to include("Nomos inline review comments")
      expect(event).to eq("COMMENT")
      expect(commit_id).to eq("abc123")
      expect(comments.length).to eq(1)
      expect(comments.first[:path]).to eq("lib/example.rb")
      expect(comments.first[:line]).to eq(2)
      expect(comments.first[:side]).to eq("RIGHT")
      expect(comments.first[:body]).to include("**Warning**")
    end

    reporter.report([finding])
  end
end
