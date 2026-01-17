# frozen_string_literal: true

module Nomos
  class Finding
    SEVERITIES = %i[message warn fail].freeze
    LEVEL_MAP = {
      "note" => :message,
      "warning" => :warn,
      "caution" => :fail
    }.freeze

    attr_reader :severity, :text, :file, :line, :code, :source

    def self.message(text, **opts)
      new(:message, text, **opts)
    end

    def self.warn(text, **opts)
      new(:warn, text, **opts)
    end

    def self.fail(text, **opts)
      new(:fail, text, **opts)
    end

    def initialize(severity, text, file: nil, line: nil, code: nil, source: "")
      unless SEVERITIES.include?(severity)
        raise ArgumentError, "Unknown severity: #{severity}"
      end

      @severity = severity
      @text = text
      @file = file
      @line = line
      @code = code
      @source = source
      freeze
    end

    def self.severity_for_level(level)
      key = level.to_s.strip.downcase
      severity = LEVEL_MAP[key]
      raise ArgumentError, "Unknown level: #{level}" unless severity

      severity
    end

    def with_severity(new_severity)
      return self if new_severity == severity

      self.class.new(new_severity, text, file: file, line: line, code: code, source: source)
    end

    def to_h
      {
        severity: severity,
        text: text,
        file: file,
        line: line,
        code: code,
        source: source
      }
    end
  end
end
