# frozen_string_literal: true

require "tempfile"
require "json"

RSpec.describe Nomos::ContextLoader do
  it "raises when missing PR context" do
    expect { described_class.load(env: {}) }.to raise_error(Nomos::Error, /Missing PR context/)
  end

  it "loads context from event and GitHub API" do
    event = {
      "pull_request" => { "number" => 12 }
    }

    file = Tempfile.new("event.json")
    file.write(JSON.generate(event))
    file.close

    client = instance_double(Nomos::GitHubClient)
    allow(client).to receive(:pull_request).and_return({
      "number" => 12,
      "base" => { "ref" => "main" }
    })
    allow(client).to receive(:pull_request_files).and_return([
      { "filename" => "README.md", "patch" => "+hello", "additions" => 1, "deletions" => 0 }
    ])

    allow(Nomos::GitHubClient).to receive(:new).and_return(client)

    context = described_class.load(env: {
      "GITHUB_EVENT_PATH" => file.path,
      "GITHUB_REPOSITORY" => "owner/repo",
      "GITHUB_TOKEN" => "token"
    })

    expect(context.repo).to eq("owner/repo")
    expect(context.base_branch).to eq("main")
    expect(context.changed_files).to eq(["README.md"])
    expect(context.changed_lines).to eq(1)
  ensure
    file.unlink
  end
end
