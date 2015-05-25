require 'spec_helper'
require 'stringio'

describe Shexec::Executor do

  subject { described_class.new }

  describe "#run(cmd, *args)" do

    it "streams the command's stdout to the caller's stdout" do
      expect { subject.run("echo", "Hello,", "world!") }.to output("Hello, world!\n").to_stdout_from_any_process
    end

    it "streams the command's stderr to the caller's stderr" do
      expect { subject.run("cat", '/nosuch\file/or\directory') }.to output(/No such file or directory/).to_stderr_from_any_process
    end

    it_behaves_like "a tainted argument objector"
    it_behaves_like "a process disconnected from the caller's stdin"
    it_behaves_like "an optionally non-blocking executor"
    it_behaves_like "an optionally time-limiting executor"
    it_behaves_like "a provider of process status"

  end

end
