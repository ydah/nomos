# frozen_string_literal: true

RSpec.describe Nomos::Context do
  it "lazy loads patches" do
    fetcher = lambda { |file| file == "README.md" ? "+change" : nil }
    context = described_class.new(
      pull_request: {},
      changed_files: ["README.md"],
      patches: {},
      patch_fetcher: fetcher,
      repo: "owner/repo",
      base_branch: "main",
      ci: {},
      changed_lines: 1
    )

    expect(context.diff("README.md")).to eq("+change")
    expect(context.diff("README.md")).to eq("+change")
  end
end
