# frozen_string_literal: true

module Nomos
  module Rules
    class Base
      attr_reader :name, :params

      def initialize(name:, params: {})
        @name = name
        @params = params
      end

      def run(_context)
        raise NotImplementedError, "Rules must implement #run"
      end
    end
  end
end
