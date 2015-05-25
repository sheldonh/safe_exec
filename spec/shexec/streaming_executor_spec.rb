require 'spec_helper'

describe Shexec::StreamingExecutor do

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  subject { described_class.new(stdout, stderr) }

  describe "#run(cmd, *args)" do

    it "writes input through a command to an output stream" do
      subject.run("echo", "Hello,", "world!")

      expect(stdout.string).to eql "Hello, world!\n"
    end

    it "accumulates the error stream of a command" do
      subject.run("cat", '/nosuch\file/or\directory')

      expect(stderr.string).to match(/No such file or directory/)
    end

    it "does not pipe the caller's stdin into the command" do
      stdin_r, _ = IO.pipe
      expect(stdin_r).to_not receive(:close)
      expect(stdin_r).to_not receive(:read)
      $stdin.reopen(stdin_r)

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
