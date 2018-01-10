require 'spec_helper'

describe Shexec::StreamingExecutor do

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  subject { described_class.new(stdout, stderr) }

  describe "#run(cmd, *args)" do

    it_behaves_like "a command-with-arguments string objector"
    it_behaves_like "a tainted argument objector"
    it_behaves_like "a stdout and stderr streamer"
    it_behaves_like "a process disconnected from the caller's stdin"
    it_behaves_like "an optionally non-blocking executor"
    it_behaves_like "an optionally time-limiting executor"
    it_behaves_like "a provider of process status"

  end

end
