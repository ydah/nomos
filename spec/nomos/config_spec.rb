# frozen_string_literal: true

require "tmpdir"

RSpec.describe Nomos::Config do
  it "loads config and exposes sections" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "nomos.yml")
      File.write(
        path,
        <<~YAML
          version: 1
          reporter:
            console: true
          performance:
            concurrency: 2
          rules:
            - name: sample
              type: builtin.no_large_pr
              params:
                max_changed_lines: 10
        YAML
      )

      config = described_class.load(path)

      expect(config.reporters).to eq({ console: true })
      expect(config.performance).to eq({ concurrency: 2 })
      expect(config.rules).to eq([
        {
          name: "sample",
          type: "builtin.no_large_pr",
          params: { max_changed_lines: 10 }
        }
      ])
    end
  end

  it "raises when config is missing" do
    expect { described_class.load("missing.yml") }.to raise_error(Nomos::Error, /Config not found/)
  end

  it "raises on invalid yaml" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "nomos.yml")
      File.write(path, "reporter: [invalid")

      expect { described_class.load(path) }.to raise_error(Nomos::Error, /Invalid YAML/)
    end
  end
end
