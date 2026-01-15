# frozen_string_literal: true

require "tempfile"

RSpec.describe Nomos::ContextLoader do
  it "raises on invalid event JSON" do
    file = Tempfile.new("event.json")
    file.write("{")
    file.close

    expect {
      described_class.load(env: {
        "GITHUB_EVENT_PATH" => file.path,
        "GITHUB_REPOSITORY" => "owner/repo"
      })
    }.to raise_error(Nomos::Error, /Invalid event JSON/)
  ensure
    file.unlink
  end

  it "falls back to NOMOS env when event path missing" do
    client = instance_double(Nomos::GitHubClient)
    allow(client).to receive(:pull_request).and_return({
      "number" => 7,
      "base" => { "ref" => "main" }
    })
    allow(client).to receive(:pull_request_files).and_return([])
    allow(Nomos::GitHubClient).to receive(:new).and_return(client)

    context = described_class.load(env: {
      "NOMOS_PR_NUMBER" => "7",
      "NOMOS_REPOSITORY" => "owner/repo"
    })

    expect(context.repo).to eq("owner/repo")
    expect(context.pull_request["number"]).to eq(7)
  end
end
