# frozen_string_literal: true

require "tmpdir"
require "json"

RSpec.describe Nomos::Cache do
  it "stores values when enabled" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "cache.json")
      cache = described_class.new(path: path, enabled: true)

      value = cache.fetch("key") { { "a" => 1 } }
      expect(value).to eq({ "a" => 1 })

      data = JSON.parse(File.read(path))
      expect(data).to eq({ "key" => { "a" => 1 } })
    end
  end

  it "bypasses when disabled" do
    cache = described_class.new(path: "unused.json", enabled: false)

    value = cache.fetch("key") { 5 }

    expect(value).to eq(5)
  end
end
