require 'spec_helper'
require 'stringio'

describe Shexec::Executor do

  subject { described_class.new }

  describe "#run(cmd, *args)" do

    it "runs a command connected to $stdout and $stderr" do
      expect { subject.run("echo", "Hello,", "world!") }.to output("Hello, world!\n").to_stdout_from_any_process
      expect { subject.run("cat", '/nosuch\file/or\directory') }.to output(/No such file or directory/).to_stderr_from_any_process
    end

    it "does not pipe the caller's stdin into the command" do
      stdin, stdin_control = IO.pipe
      $stdin.reopen(stdin)
      stdin_control.puts "Hello, world!\n"
      stdin_control.close

      expect { subject.run("cat") }.to_not output.to_stdout_from_any_process
    end

    it "can be run in non-blocking mode" do
      subject.run("cat") do |t|
        while t.alive?
          $stderr.puts "    ...doing something interesting while we wait for the process to complete"
          sleep(0.01)
        end
      end
    end

  end

end
