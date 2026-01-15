# frozen_string_literal: true

require "json"

module Nomos
  class Cache
    def initialize(path:, enabled: true)
      @path = path
      @enabled = enabled
      @data = enabled ? load_data : {}
    end

    def fetch(key)
      return yield unless @enabled
      return @data[key] if @data.key?(key)

      value = yield
      @data[key] = value
      persist
      value
    end

    private

    def load_data
      return {} unless File.exist?(@path)

      JSON.parse(File.read(@path))
    rescue JSON::ParserError
      {}
    end

    def persist
      dir = File.dirname(@path)
      Dir.mkdir(dir) unless Dir.exist?(dir)
      File.write(@path, JSON.pretty_generate(@data))
    end
  end
end
