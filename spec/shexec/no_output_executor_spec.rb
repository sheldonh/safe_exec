require 'spec_helper'

describe Shexec::NoOutputExecutor do

  subject { described_class.new }

  describe "#run(cmd, *args)" do

    it "runs a command and discards its stdout and stderr" do
      expect { subject.run("echo", "Hello,", "world!") }.to_not output.to_stdout_from_any_process
      expect { subject.run("cat", '/nosuch\file/or\directory') }.to_not output.to_stderr_from_any_process
    end

    it "does not pipe the caller's stdin into the command" do
      stdin, _ = IO.pipe
      expect(stdin).to_not receive(:close)
      expect(stdin).to_not receive(:read)
      $stdin.reopen(stdin)

      subject.run("cat")
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
