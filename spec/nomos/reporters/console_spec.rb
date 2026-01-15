# frozen_string_literal: true

RSpec.describe Nomos::Reporters::Console do
  it "prints no findings message" do
    reporter = described_class.new

    expect { reporter.report([]) }.to output(/no findings/i).to_stdout
  end

  it "prints findings with location" do
    reporter = described_class.new
    finding = Nomos::Finding.warn("Warn", file: "README.md", line: 2, source: "spec")

    expect { reporter.report([finding]) }.to output(/\[warn\] Warn \(README.md:2\)/).to_stdout
  end
end
