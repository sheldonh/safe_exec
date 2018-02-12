require 'safe_exec/pipe_executor'

module SafeExec

  class Executor < PipeExecutor

    def initialize
      super(StringIO.new.tap { |io| io.close }, $stdout, $stderr)
    end

  end

end
