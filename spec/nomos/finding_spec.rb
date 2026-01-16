# frozen_string_literal: true

RSpec.describe Nomos::Finding do
  it "serializes to hash" do
    finding = described_class.warn("Warn", file: "README.md", line: 3, code: "W1", source: "spec")

    expect(finding.to_h).to eq(
      severity: :warn,
      text: "Warn",
      file: "README.md",
      line: 3,
      code: "W1",
      source: "spec"
    )
  end

  it "rejects unknown severities" do
    expect {
      described_class.new(:nope, "bad", source: "spec")
    }.to raise_error(ArgumentError, /Unknown severity/)
  end
end
