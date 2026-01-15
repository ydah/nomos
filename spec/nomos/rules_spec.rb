# frozen_string_literal: true

RSpec.describe Nomos::Rules do
  def build_context(changed_files:, changed_lines:, pull_request: { "number" => 1 }, patches: {})
    Nomos::Context.new(
      pull_request: pull_request,
      changed_files: changed_files,
      patches: patches,
      repo: "owner/repo",
      base_branch: "main",
      ci: {},
      changed_lines: changed_lines
    )
  end

  it "builds builtin rules" do
    rule = described_class.build(name: "sample", type: "builtin.no_large_pr", params: { max_changed_lines: 5 })
    expect(rule).to be_a(Nomos::Rules::Builtin::NoLargePr)

    rule = described_class.build(name: "forbid", type: "builtin.forbid_paths", params: { patterns: ["secret/*"] })
    expect(rule).to be_a(Nomos::Rules::Builtin::ForbidPaths)
  end

  it "builds ruby file rules" do
    rule = described_class.build(name: "custom", type: "ruby.file", params: { path: ".nomos/rules.rb" })
    expect(rule).to be_a(Nomos::Rules::RubyFile)
  end

  it "raises on unknown rule type" do
    expect {
      described_class.build(name: "sample", type: "unknown", params: {})
    }.to raise_error(Nomos::Error, /Unknown rule type/)
  end

  it "flags large PRs" do
    context = build_context(changed_files: ["README.md"], changed_lines: 12)
    rule = Nomos::Rules::Builtin::NoLargePr.new(name: "large", params: { max_changed_lines: 10 })

    findings = rule.run(context)

    expect(findings.length).to eq(1)
    expect(findings.first.severity).to eq(:fail)
  end

  it "requires files to change" do
    context = build_context(changed_files: ["lib/nomos.rb"], changed_lines: 1)
    rule = Nomos::Rules::Builtin::RequireFileChange.new(
      name: "changelog",
      params: { patterns: ["CHANGELOG.md"] }
    )

    findings = rule.run(context)

    expect(findings.length).to eq(1)
    expect(findings.first.text).to include("Required files not changed")
  end

  it "forbids matching paths" do
    context = build_context(changed_files: ["secret/key.txt"], changed_lines: 1)
    rule = Nomos::Rules::Builtin::ForbidPaths.new(
      name: "forbid",
      params: { patterns: ["secret/*"] }
    )

    findings = rule.run(context)

    expect(findings.length).to eq(1)
    expect(findings.first.text).to include("Forbidden paths changed")
  end

  it "requires labels to be present" do
    context = build_context(
      changed_files: ["README.md"],
      changed_lines: 1,
      pull_request: { "number" => 1, "labels" => [{ "name" => "ready" }] }
    )
    rule = Nomos::Rules::Builtin::RequireLabels.new(
      name: "labels",
      params: { labels: ["ready", "approved"] }
    )

    findings = rule.run(context)

    expect(findings.length).to eq(1)
    expect(findings.first.text).to include("Missing required labels")
  end

  it "flags TODOs in diffs" do
    context = build_context(
      changed_files: ["lib/nomos.rb"],
      changed_lines: 1,
      patches: { "lib/nomos.rb" => "+ # TODO: fix" }
    )
    rule = Nomos::Rules::Builtin::TodoGuard.new(name: "todo", params: {})

    findings = rule.run(context)

    expect(findings.length).to eq(1)
    expect(findings.first.text).to include("TODO found in diffs")
  end
end
