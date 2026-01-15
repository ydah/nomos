# frozen_string_literal: true

RSpec.describe Nomos::Timing do
  it "records entries" do
    timing = described_class.new

    result = timing.measure("step") { 2 + 2 }

    expect(result).to eq(4)
    expect(timing.entries.length).to eq(1)
    expect(timing.entries.first.label).to eq("step")
  end
end
