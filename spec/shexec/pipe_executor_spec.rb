require 'spec_helper'
require 'stringio'

describe Shexec::PipeExecutor do

  describe "#run(cmd, *args)" do

    it "writes input through a command to an output stream" do
      stdin = StringIO.new("Hello, world!\n").tap { |io| io.close_write }
      stdout = StringIO.new
      stderr = StringIO.new

      shexec = Shexec::PipeExecutor.new(stdin, stdout, stderr)
      shexec.run("cat")

      expect(stdout.string).to eql "Hello, world!\n"
    end

    it "accumulates the error stream of a command" do
      stdin = StringIO.new.tap { |io| io.close_write }
      stdout = StringIO.new
      stderr = StringIO.new

      shexec = Shexec::PipeExecutor.new(stdin, stdout, stderr)
      shexec.run("cat", '/nosuch\file/or\directory')

      expect(stderr.string).to match(/No such file or directory/)
    end

    it "can be run in non-blocking mode" do
      stdin_r, stdin_w = IO.pipe
      stdout = StringIO.new
      stderr = StringIO.new

      shexec = Shexec::PipeExecutor.new(stdin_r, stdout, stderr)
      shexec.run("cat") do |t|
        stdin_w.write "Hello,"
        stdin_w.write " world!\n"
        stdin_w.close

        while t.alive?
          $stderr.puts "    ...doing something interesting while we wait for the process to complete"
          sleep(0.01)
        end
      end

      expect(stdout.string).to eql "Hello, world!\n"
    end

    it "raises a SecurityError if the command or arguments contain tainted strings" do
      stdin = StringIO.new.tap { |io| io.close_write }
      stdout = StringIO.new
      stderr = StringIO.new

      shexec = Shexec::PipeExecutor.new(stdin, stdout, stderr)
      expect { shexec.run('cat; rm -rf /tmp/nosuch\file/or\directory'.taint) }.to raise_error SecurityError
      expect { shexec.run('cat', '/tmp/tmp.Xm48jh3/../../etc/shadow'.taint) }.to raise_error SecurityError
    end

  end

end
