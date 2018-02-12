require 'safe_exec/executor'

module SafeExec

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
