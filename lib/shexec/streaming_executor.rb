module Shexec

  class StreamingExecutor < Executor

    def initialize(stdout, stderr)
      super()
      @stdout = stdout
      @stderr = stderr
    end

  end

end
