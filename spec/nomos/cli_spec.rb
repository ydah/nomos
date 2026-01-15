# frozen_string_literal: true

RSpec.describe Nomos::CLI do
  def build_finding(severity)
    Nomos::Finding.new(severity, "message", source: "spec")
  end

  it "returns 0 when only warn and not strict" do
    config = instance_double(Nomos::Config, reporters: { console: true }, rules: [])
    context = instance_double(Nomos::Context)
    runner = instance_double(Nomos::Runner, run: [build_finding(:warn)])

    allow(Nomos::Config).to receive(:load).and_return(config)
    allow(Nomos::ContextLoader).to receive(:load).and_return(context)
    allow(Nomos::Runner).to receive(:new).and_return(runner)
    allow_any_instance_of(described_class).to receive(:build_reporters).and_return([instance_double(Nomos::Reporters::Console, report: nil)])

    code = described_class.run(["run"])

    expect(code).to eq(0)
  end

  it "returns 1 when warn and strict" do
    config = instance_double(Nomos::Config, reporters: { console: true }, rules: [])
    context = instance_double(Nomos::Context)
    runner = instance_double(Nomos::Runner, run: [build_finding(:warn)])

    allow(Nomos::Config).to receive(:load).and_return(config)
    allow(Nomos::ContextLoader).to receive(:load).and_return(context)
    allow(Nomos::Runner).to receive(:new).and_return(runner)
    allow_any_instance_of(described_class).to receive(:build_reporters).and_return([instance_double(Nomos::Reporters::Console, report: nil)])

    code = described_class.run(["run", "--strict"])

    expect(code).to eq(1)
  end

  it "returns 1 when fail is present" do
    config = instance_double(Nomos::Config, reporters: { console: true }, rules: [])
    context = instance_double(Nomos::Context)
    runner = instance_double(Nomos::Runner, run: [build_finding(:fail)])

    allow(Nomos::Config).to receive(:load).and_return(config)
    allow(Nomos::ContextLoader).to receive(:load).and_return(context)
    allow(Nomos::Runner).to receive(:new).and_return(runner)
    allow_any_instance_of(described_class).to receive(:build_reporters).and_return([instance_double(Nomos::Reporters::Console, report: nil)])

    code = described_class.run(["run"])

    expect(code).to eq(1)
  end

  it "returns 1 on unknown command" do
    code = described_class.run(["unknown"])

    expect(code).to eq(1)
  end
end
