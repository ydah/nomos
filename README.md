# Nomos

Ultra-fast Danger-like CI linter for GitHub pull requests.

Nomos evaluates PR metadata and diffs, then reports findings as `message`, `warn`, or `fail`.

## Phase 1 Usage

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

### Config

Create `nomos.yml`:

```yml
version: 1

reporter:
  github: true
  console: true

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

Examples:

- `examples/nomos.yml`
- `examples/.nomos/rules.rb`

### CLI

```
nomos run [--config PATH] [--strict] [--debug] [--reporter github,console,json]
nomos init
nomos doctor
```

### Ruby DSL

Define rules in `.nomos/rules.rb`:

```rb
rule "no_debugger" do
  changed_files.grep(/\\.rb$/).each do |file|
    if diff(file).include?("binding.pry")
      fail "binding.pry detected", file: file
    end
  end
end
```

## Development

Run tests:

```bash
bundle exec rspec
```

## License

MIT
