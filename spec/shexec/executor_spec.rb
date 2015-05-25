require 'spec_helper'
require 'stringio'

describe Shexec::Executor do

  describe "#run(cmd, *args)" do

    it "runs a command connected to $stdout and $stderr" do
      shexec = Shexec::Executor.new
      expect { shexec.run("echo", "Hello,", "world!") }.to output("Hello, world!\n").to_stdout_from_any_process
      expect { shexec.run("cat", '/nosuch\file/or\directory') }.to output(/No such file or directory/).to_stderr_from_any_process
    end

    it "does not pipe the caller's stdin into the command" do
      stdin_r, stdin_w = IO.pipe
      $stdin.reopen(stdin_r)
      stdin_w.puts "Hello, world!\n"
      stdin_w.close

      shexec = Shexec::Executor.new
      expect { shexec.run("cat") }.to_not output.to_stdout_from_any_process
    end

    it "can be run in non-blocking mode" do
      shexec = Shexec::Executor.new
      shexec.run("cat") do |t|
        while t.alive?
          $stderr.puts "    ...doing something interesting while we wait for the process to complete"
          sleep(0.01)
        end
      end
    end

  end

end
