require 'shexec/pipe_executor'

module Shexec

  class Executor < PipeExecutor

    def initialize
      @stdin = StringIO.new.tap { |io| io.close }
      @stdout = $stdout
      @stderr = $stderr
    end

  end

end
