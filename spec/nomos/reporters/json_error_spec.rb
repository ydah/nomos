# frozen_string_literal: true

RSpec.describe Nomos::Reporters::Json do
  it "raises when file cannot be written" do
    dir = Dir.mktmpdir
    reporter = described_class.new(path: dir)

    expect { reporter.report([]) }.to raise_error(Errno::EISDIR)
  ensure
    Dir.rmdir(dir) if dir && Dir.exist?(dir)
  end
end
