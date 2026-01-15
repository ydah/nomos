# frozen_string_literal: true

module Nomos
  class Finding
    SEVERITIES = %i[message warn fail].freeze

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
