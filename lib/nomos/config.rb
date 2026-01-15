# frozen_string_literal: true

require "yaml"

module Nomos
  class Config
    DEFAULT_PATH = "nomos.yml"

    attr_reader :path, :data

    def self.load(path = DEFAULT_PATH)
      raw = read_yaml(path)
      new(path, raw)
    end

    def initialize(path, raw)
      @path = path
      @data = symbolize_keys(raw || {})
    end

    def reporters
      data.fetch(:reporter, {})
    end

    def performance
      data.fetch(:performance, {})
    end

    def rules
      Array(data[:rules])
    end

    private

    def self.read_yaml(path)
      unless File.exist?(path)
        raise Nomos::Error, "Config not found: #{path}"
      end

      YAML.safe_load(File.read(path), permitted_classes: [], aliases: false) || {}
    rescue Psych::SyntaxError => e
      raise Nomos::Error, "Invalid YAML in #{path}: #{e.message}"
    end

    def symbolize_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(key, value), memo|
          memo[key.to_sym] = symbolize_keys(value)
        end
      when Array
        obj.map { |value| symbolize_keys(value) }
      else
        obj
      end
    end
  end
end
