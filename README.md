<p align="center">
  <img src="docs/logo-header.svg" alt="nomos header logo">
  <strong>Bring harmony to your pull requests.</strong>
</p>
<p align="center">
  <img src="https://img.shields.io/badge/ruby-%3E%3D%203.2-ruby.svg" alt="Ruby Version">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License">
  <a href="https://github.com/ydah/nomos/actions/workflows/main.yml">
    <img src="https://github.com/ydah/nomos/actions/workflows/main.yml/badge.svg" alt="CI Status">
  </a>
</p>

<p align="center">
  <a href="#features">Features</a> ·
  <a href="#installation">Installation</a> ·
  <a href="#quick-start">Quick Start</a> ·
  <a href="#configuration">Configuration</a> ·
  <a href="#rules">Rules</a> ·
  <a href="#reporters">Reporters</a> ·
  <a href="#how-it-works">How It Works</a>
</p>

---

Nomos evaluates PR metadata and diffs, then reports findings as `message`, `warn`, or `fail`.
It is designed for fast startup, minimal API calls, and clear configuration.

## Features

<a name="features"></a>

- Diff-driven by default with optional lazy diff fetching
- Built-in cache to avoid redundant GitHub API calls
- Parallel rule execution
- Built-in rules plus Ruby DSL for custom checks
- Multiple reporters: GitHub comment, console, JSON
- Strict mode for CI gating

## Installation

<a name="installation"></a>

Add to your Gemfile:

```ruby
gem "nomos"
```

Then install:

```bash
bundle install
```

## Quick Start

<a name="quick-start"></a>

Run in CI or locally:

```bash
nomos run
```

### Required ENV

- `GITHUB_TOKEN` (GitHub API token)
- `GITHUB_REPOSITORY` (e.g. `owner/repo`)
- `GITHUB_EVENT_PATH` (path to GitHub event JSON)

Local override:

- `NOMOS_REPOSITORY` and `NOMOS_PR_NUMBER` if `GITHUB_EVENT_PATH` is not available

### GitHub Actions

```yaml
- name: Nomos
  run: nomos run
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Configuration

<a name="configuration"></a>

Create `nomos.yml`:

```yml
version: 1

reporter:
  github: true
  console: true

performance:
  concurrency: 4
  cache: true
  lazy_diff: true
  timing: false

rules:
  - name: no_large_pr
    type: builtin.no_large_pr
    params:
      max_changed_lines: 800

  - name: require_changelog
    type: builtin.require_file_change
    params:
      patterns:
        - CHANGELOG.md

  - name: custom_rules
    type: ruby.file
    params:
      path: .nomos/rules.rb
```

Performance notes:

- Cache file defaults to `.nomos/cache.json` (override with `performance.cache_path`)
- Use `--no-cache` to disable cache and lazy diff for a single run

### CLI

```
nomos run [--config PATH] [--strict] [--debug] [--no-cache] [--reporter github,console,json]
nomos init
nomos doctor
```

## Rules

<a name="rules"></a>

### Built-in rules

- `builtin.no_large_pr`
- `builtin.require_file_change`
- `builtin.forbid_paths`
- `builtin.require_labels`
- `builtin.todo_guard`

### Ruby DSL (`.nomos/rules.rb`)

```rb
rule "no_debugger" do
  changed_files.grep(/\.rb$/).each do |file|
    if diff(file).include?("binding.pry")
      fail "binding.pry detected", file: file
    end
  end
end
```

Available DSL helpers:

- `changed_files`, `diff(file)`
- `pr_title`, `pr_body`, `pr_number`, `pr_author`, `pr_labels`
- `repo`, `base_branch`, `ci`

### Adding custom rules

1. Create `.nomos/rules.rb` and define one or more `rule "name"` blocks.
2. Register the file in `nomos.yml` under `rules` with `type: ruby.file` and `params.path: .nomos/rules.rb`.
3. Run `nomos run` (or your CI job) to verify the rule executes.

Example:

```rb
# .nomos/rules.rb
rule "require_docs_change" do
  unless changed_files.any? { |file| file.start_with?("docs/") }
    fail "Docs must be updated for this change", file: "docs/"
  end
end
```

```yml
# nomos.yml
rules:
  - name: require_docs_change
    type: ruby.file
    params:
      path: .nomos/rules.rb
```

## Reporters

<a name="reporters"></a>

- GitHub comment reporter
- Console reporter
- JSON reporter (for post-processing)

## How It Works

<a name="how-it-works"></a>

1. Load PR context from GitHub API or event payload
2. Fetch changed files and patches (lazy diff optional)
3. Run rules in parallel where safe
4. Report findings to configured outputs
5. Exit with CI-friendly status

## Development

```bash
bundle exec rspec
```

## License

MIT License. See `LICENSE` file for details.
