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

  it "uses cache to avoid repeated API calls" do
    event = {
      "pull_request" => { "number" => 12 }
    }

    event_file = Tempfile.new("event.json")
    event_file.write(JSON.generate(event))
    event_file.close

    cache_file = Tempfile.new("cache.json")
    cache_file.close

    client = instance_double(Nomos::GitHubClient)
    expect(client).to receive(:pull_request).once.and_return({
      "number" => 12,
      "base" => { "ref" => "main" }
    })
    expect(client).to receive(:pull_request_files).once.and_return([
      { "filename" => "README.md", "patch" => "+hello", "additions" => 1, "deletions" => 0 }
    ])
    allow(Nomos::GitHubClient).to receive(:new).and_return(client)

    env = {
      "GITHUB_EVENT_PATH" => event_file.path,
      "GITHUB_REPOSITORY" => "owner/repo",
      "GITHUB_TOKEN" => "token"
    }
    performance = { cache: true, cache_path: cache_file.path }

    described_class.load(env: env, performance: performance)
    context = described_class.load(env: env, performance: performance)

    expect(context.changed_files).to eq(["README.md"])
  ensure
    event_file.unlink
    cache_file.unlink
  end
end
