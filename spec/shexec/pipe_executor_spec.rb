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

    it "writes input through a command to an output stream" do
      stdin_control.puts "Hello, world!"
      stdin_control.close
      subject.run("cat")

      expect(stdout.string).to eql "Hello, world!\n"
    end

    it "accumulates the error stream of a command" do
      stdin_control.close
      subject.run("cat", '/nosuch\file/or\directory')

      expect(stderr.string).to match(/No such file or directory/)
    end

    it "can be run in non-blocking mode" do
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

    it "raises a SecurityError if the command or arguments contain tainted strings" do
      stdin_control.close

      expect { subject.run('cat; rm -rf /tmp/nosuch\file/or\directory'.taint) }.to raise_error SecurityError
      expect { subject.run('cat', '/tmp/tmp.Xm48jh3/../../etc/shadow'.taint) }.to raise_error SecurityError
    end

  end

end
