# frozen_string_literal: true

RSpec.describe Nomos::Rules::RubyDSL::RuleContext do
  let(:context) do
    Nomos::Context.new(
      pull_request: {
        "number" => 12,
        "title" => "Add feature",
        "body" => "Details",
        "user" => { "login" => "octocat" },
        "labels" => [{ "name" => "infra" }, { "name" => "urgent" }]
      },
      changed_files: ["lib/example.rb"],
      patches: { "lib/example.rb" => "+change" },
      repo: "owner/repo",
      base_branch: "main",
      ci: { "workflow" => "CI" },
      changed_lines: 1
    )
  end

  let(:rule_context) { described_class.new(context, "rule") }

  it "exposes PR metadata helpers" do
    expect(rule_context.pr_title).to eq("Add feature")
    expect(rule_context.pr_body).to eq("Details")
    expect(rule_context.pr_number).to eq(12)
    expect(rule_context.pr_author).to eq("octocat")
    expect(rule_context.pr_labels).to eq(["infra", "urgent"])
  end

  it "exposes repository helpers" do
    expect(rule_context.repo).to eq("owner/repo")
    expect(rule_context.base_branch).to eq("main")
    expect(rule_context.ci).to eq({ "workflow" => "CI" })
  end
end
