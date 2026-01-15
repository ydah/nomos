# frozen_string_literal: true

require "tmpdir"

RSpec.describe Nomos::Rules::RubyFile do
  def build_context
    Nomos::Context.new(
      pull_request: { "number" => 1 },
      changed_files: ["lib/example.rb"],
      patches: { "lib/example.rb" => "+binding.pry" },
      repo: "owner/repo",
      base_branch: "main",
      ci: {},
      changed_lines: 1
    )
  end

  it "loads rule file and reports findings" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "rules.rb")
      File.write(
        path,
        <<~RUBY
          rule "no_debugger" do
            changed_files.grep(/\.rb$/).each do |file|
              if diff(file).include?("binding.pry")
                fail "binding.pry detected", file: file
              end
            end
          end
        RUBY
      )

      rule = described_class.new(name: "custom", params: { path: path })
      findings = rule.run(build_context)

      expect(findings.length).to eq(1)
      expect(findings.first.text).to include("binding.pry")
      expect(findings.first.source).to eq("no_debugger")
    end
  end
end
