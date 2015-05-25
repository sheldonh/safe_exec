require 'spec_helper'

describe Shexec::NoOutputExecutor do

  describe "#run(cmd, *args)" do

    it "runs a command and discards its stdout and stderr" do
      shexec = Shexec::NoOutputExecutor.new
      expect { shexec.run("echo", "Hello,", "world!") }.to_not output.to_stdout_from_any_process
      expect { shexec.run("cat", '/nosuch\file/or\directory') }.to_not output.to_stderr_from_any_process
    end

    it "does not pipe the caller's stdin into the command" do
      stdin_r, _ = IO.pipe
      expect(stdin_r).to_not receive(:close)
      expect(stdin_r).to_not receive(:read)
      $stdin.reopen(stdin_r)

      shexec = Shexec::NoOutputExecutor.new
      shexec.run("cat")
    end

    it "can be run in non-blocking mode" do
      shexec = Shexec::NoOutputExecutor.new
      shexec.run("cat") do |t|
        while t.alive?
          $stderr.puts "    ...doing something interesting while we wait for the process to complete"
          sleep(0.01)
        end
      end
    end

  end

end
