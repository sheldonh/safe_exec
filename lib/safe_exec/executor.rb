require 'safe_exec/pipe_executor'
require "stringio"

module SafeExec

  class Executor < PipeExecutor

    def initialize
      super(StringIO.new.tap { |io| io.close }, $stdout, $stderr)
    end

  end

end
