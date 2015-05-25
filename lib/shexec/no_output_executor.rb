require 'shexec/executor'

module Shexec

  class NoOutputExecutor < Executor

    module NullIO
      def self.write(string)
      end

      def self.flush
      end
    end

    def initialize
      super
      @stdout = NullIO
      @stderr = NullIO
    end

  end

end
