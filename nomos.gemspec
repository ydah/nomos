# frozen_string_literal: true

require_relative "lib/nomos/version"

Gem::Specification.new do |spec|
  spec.name = "nomos"
  spec.version = Nomos::VERSION
  spec.authors = ["Yudai Takada"]
  spec.email = ["t.yudai92@gmail.com"]

  spec.summary = "Evaluate GitHub pull requests with configurable rules."
  spec.description = "Nomos evaluates pull request metadata and diffs, then reports findings as message, warn, or fail. It is designed for fast startup, minimal GitHub API calls, and clear configuration."
  spec.homepage = "https://github.com/ydah/nomos"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ydah/nomos"
  spec.metadata["changelog_uri"] = "https://github.com/ydah/nomos/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/ydah/nomos/issues"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
