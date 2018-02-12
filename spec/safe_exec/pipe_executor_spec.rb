require 'spec_helper'
require 'stringio'

describe SafeExec::PipeExecutor do

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

    describe "deadlock prevention" do

      let(:four_megabytes) { "x" * (4 * 1024 * 1024) }

      it "prevents deadlock for output streams that don't block (e.g. StringIO, File)" do
        subject.run("cat") do |t|
          stdin_control.write four_megabytes
          stdin_control.close
        end
        expect(stdout.string).to eql four_megabytes
      end

      context "when output streams block (e.g. they are undrained pipes)" do
        let(:stdout_pipe) { IO.pipe }
        let(:stdout) { stdout_pipe[1] }

        it "can't prevent deadlock" do
          expect { subject.timeout(0.5).run("cat") { |t|
            stdin_control.write four_megabytes
            stdin_control.close
          } }.to raise_error Timeout::Error
        end

      end

    end

    context do
      before(:each) { stdin_control.close }
      it_behaves_like "a command-with-arguments string objector"
      it_behaves_like "a tainted argument objector"
      it_behaves_like "a stdout and stderr streamer"
      it_behaves_like "an optionally non-blocking executor"
      it_behaves_like "an optionally time-limiting executor"
      it_behaves_like "a provider of process status"
    end

  end

end
