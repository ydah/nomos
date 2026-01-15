# frozen_string_literal: true

module Nomos
  class Timing
    Entry = Struct.new(:label, :duration_ms, keyword_init: true)

    def initialize
      @entries = []
    end

    def measure(label)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = yield
      finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      duration_ms = ((finish - start) * 1000).round(2)
      @entries << Entry.new(label: label, duration_ms: duration_ms)
      result
    end

    def entries
      @entries.dup
    end

    def report(io = $stderr)
      return if @entries.empty?

      io.puts "Nomos timing (ms):"
      @entries.each do |entry|
        io.puts "- #{entry.label}: #{entry.duration_ms}"
      end
    end
  end
end
