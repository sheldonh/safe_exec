require 'open3'

module Shexec

  class PipeExecutor

    PAGE_SIZE = 4096

    def initialize(stdin, stdout, stderr)
      @stdin, @stdout, @stderr = stdin, stdout, stderr
    end

    def run(cmd, *args)
      assert_untainted_command(cmd, *args)
      threads = []
      Open3.popen3([cmd, cmd], *args) do |stdin, stdout, stderr, wait_thr|
        threads << pusher(@stdin, stdin)
        threads << drainer(stdout, @stdout)
        threads << drainer(stderr, @stderr)

        yield wait_thr if block_given?

        wait_thr.value.tap { threads.each { |t| t.join } }
      end
    end

    private

      def pusher(input, output)
        Thread.new do
          stream(input, output)
          output.close unless output.closed?
        end
      end

      def drainer(input, output)
        Thread.new do
          stream(input, output)
          output.flush
        end
      end

      def stream(input, output)
        until input.closed? or input.eof?
          output.write input.read(PAGE_SIZE)
        end
      end

      def assert_untainted_command(*components)
        components.each do |component|
          raise SecurityError.new("refusing to construct a command line from tainted component #{component}") if component.tainted?
        end
      end

  end

end
