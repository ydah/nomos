# frozen_string_literal: true

RSpec.describe Nomos::Runner do
  let(:config) { instance_double(Nomos::Config, rules: [rule_config], performance: { concurrency: 1 }) }
  let(:context) { instance_double(Nomos::Context) }
  let(:rule_config) { { name: "sample", type: "builtin.no_large_pr", params: {} } }

  it "collects findings from rules" do
    rule = instance_double(Nomos::Rules::Builtin::NoLargePr)
    allow(Nomos::Rules).to receive(:build).and_return(rule)
    allow(rule).to receive(:run).and_return([Nomos::Finding.warn("warn", source: "sample")])

    findings = described_class.new(config, context).run

    expect(findings.length).to eq(1)
    expect(findings.first.severity).to eq(:warn)
  end

  it "turns rule errors into fail findings" do
    rule = instance_double(Nomos::Rules::Builtin::NoLargePr, name: "boom")
    allow(Nomos::Rules).to receive(:build).and_return(rule)
    allow(rule).to receive(:run).and_raise(StandardError, "bad")

    findings = described_class.new(config, context).run

    expect(findings.length).to eq(1)
    expect(findings.first.severity).to eq(:fail)
    expect(findings.first.text).to include("Rule boom failed")
  end

  it "runs rules in parallel when concurrency is set" do
    parallel_config = instance_double(Nomos::Config, rules: [rule_config, rule_config], performance: { concurrency: 2 })
    rule = instance_double(Nomos::Rules::Builtin::NoLargePr, name: "rule")

    allow(Nomos::Rules).to receive(:build).and_return(rule)
    allow(rule).to receive(:run).and_return([])

    findings = described_class.new(parallel_config, context).run

    expect(findings).to eq([])
    expect(Nomos::Rules).to have_received(:build).twice
  end
end
