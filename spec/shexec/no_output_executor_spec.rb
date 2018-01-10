require 'spec_helper'

describe Shexec::NoOutputExecutor do

  subject { described_class.new }

  describe "#run(cmd, *args)" do

    it "discards the command's stdout" do
      expect { subject.run("echo", "Hello,", "world!") }.to_not output.to_stdout_from_any_process
    end

    it "discards the command's stderr" do
      expect { subject.run("cat", '/nosuch\file/or\directory') }.to_not output.to_stderr_from_any_process
    end

    it_behaves_like "a command-with-arguments string objector"
    it_behaves_like "a tainted argument objector"
    it_behaves_like "a process disconnected from the caller's stdin"
    it_behaves_like "an optionally non-blocking executor"
    it_behaves_like "an optionally time-limiting executor"
    it_behaves_like "a provider of process status"

  end

end
