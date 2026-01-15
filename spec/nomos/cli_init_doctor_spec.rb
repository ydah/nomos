# frozen_string_literal: true

require "tmpdir"
require "stringio"

RSpec.describe Nomos::CLI do
  def run_in_dir(dir, *args)
    Dir.chdir(dir) { described_class.run(args) }
  end

  it "creates config and rules on init" do
    Dir.mktmpdir do |dir|
      code = run_in_dir(dir, "init")

      expect(code).to eq(0)
      expect(File).to exist(File.join(dir, "nomos.yml"))
      expect(File).to exist(File.join(dir, ".nomos/rules.rb"))
    end
  end

  it "reports missing env in doctor" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "nomos.yml"), "version: 1\n")

      output = capture_output do
        Dir.chdir(dir) { with_env("GITHUB_TOKEN" => nil, "GITHUB_EVENT_PATH" => nil, "NOMOS_PR_NUMBER" => nil, "NOMOS_REPOSITORY" => nil) { described_class.run(["doctor"]) } }
      end

      expect(output).to include("Missing GITHUB_TOKEN")
      expect(output).to include("Missing PR context")
    end
  end

  def capture_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    "#{$stdout.string}#{$stderr.string}"
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def with_env(new_env)
    original = ENV.to_hash
    new_env.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
    yield
  ensure
    ENV.replace(original)
  end
end
