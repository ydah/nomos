# frozen_string_literal: true

require "json"
require "tempfile"

RSpec.describe Nomos::Reporters::Json do
  it "writes findings to json file" do
    file = Tempfile.new("nomos-report.json")
    file.close

    reporter = described_class.new(path: file.path)
    findings = [Nomos::Finding.warn("Warn", source: "spec")]

    reporter.report(findings)

    data = JSON.parse(File.read(file.path))

    expect(data.fetch("counts").fetch("warn")).to eq(1)
    expect(data.fetch("findings").length).to eq(1)
  ensure
    file.unlink
  end
end
