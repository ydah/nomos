# frozen_string_literal: true

RSpec.describe Nomos do
  it "exposes a version string" do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
