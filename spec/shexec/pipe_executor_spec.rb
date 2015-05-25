require 'spec_helper'
require 'stringio'

describe Shexec::PipeExecutor do

  let(:control_pipe) { IO.pipe }
  let(:stdin_control) { control_pipe[1] }
  let(:stdin) { control_pipe[0] }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  subject { described_class.new(stdin, stdout, stderr) }

  describe "#run(cmd, *args)" do

    it "streams the instance's stdin stream into the command's stdin stream" do
      stdin_control.puts "Hello, world!"
      stdin_control.close
      subject.run("cat")

      expect(stdout.string).to eql "Hello, world!\n"
    end

    it "can stream into the command's stdin in non-blocking mode" do
      subject.run("cat") do |t|
        stdin_control.write "Hello,"
        stdin_control.write " world!\n"
        stdin_control.close

        while t.alive?
          $stderr.puts "    ...doing something interesting while we wait for the process to complete"
          sleep(0.01)
        end
      end

      expect(stdout.string).to eql "Hello, world!\n"
    end

    context do
      before(:each) { stdin_control.close }
      it_behaves_like "a tainted argument objector"
      it_behaves_like "a stdout and stderr streamer"
      it_behaves_like "an optionally non-blocking executor"
      it_behaves_like "a provider of process status"
    end

  end

end
