require 'open3'
require 'timeout'
require 'thread'

module SafeExec

  class PipeExecutor

    PAGE_SIZE = 4096

    def initialize(stdin, stdout, stderr)
      @stdin, @stdout, @stderr = stdin, stdout, stderr
      @mutex = Mutex.new
    end

    def run(cmd, *args)
      assert_untainted_command(cmd, *args)
      @mutex.synchronize do
        Open3.popen3([cmd, cmd], *args) do |stdin, stdout, stderr, wait_thr|
          @threads = [
            pusher(@stdin, stdin),
            drainer(stdout, @stdout),
            drainer(stderr, @stderr)
          ]
          @threads.each { |t| t.abort_on_exception = true }

          yield wait_thr if block_given?

          wait_thr.value.tap { @threads.each { |t| t.join } }
        end
      end
    end

    def timeout(seconds, exception = Timeout::Error)
      TimeoutDelegate.new(self, seconds, exception)
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
        until input.closed?
          page = input.read(PAGE_SIZE)
          if page
            output.write(page)
          else
            break
          end
        end
      end

      def assert_untainted_command(*components)
        components.each do |component|
          raise SecurityError.new("refusing to construct a command line from tainted component #{component}") if component.tainted?
        end
      end

      def abort
        @threads.each { |t| t.kill }
      end

      class TimeoutDelegate

        def initialize(executor, timeout, exception)
          @executor, @timeout, @exception = executor, timeout, exception
        end

        def run(cmd, *args)
          @executor.run(cmd, *args) do |t|
            begin
              Timeout.timeout(@timeout, @exception) do
                yield t if block_given?
                t.value
              end
            rescue @exception => e
              begin
                @executor.send(:abort)
                Process.kill("TERM", t.pid)
              rescue Errno::ESRCH
              ensure
                raise e
              end
            end
          end
        end

      end

  end

end
