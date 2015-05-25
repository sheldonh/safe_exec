require 'shexec/pipe_executor'

module Shexec

  class Executor < PipeExecutor

    def initialize
      super(StringIO.new.tap { |io| io.close }, $stdout, $stderr)
    end

  end

end
