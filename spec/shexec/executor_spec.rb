require 'spec_helper'
require 'stringio'

# TODO Check whether rspec's output matcher has become thread-safe.
# It would be wonderful to do
#
#   expect { shexec.run("echo", "Hello,", "world!") }.to output("Hello, world!\n").to_stdout
#
# But this issue prevents it: https://github.com/rspec/rspec-expectations/issues/642

describe Shexec::Executor do

  describe "#run(cmd, *args)" do

    it "runs a command connected to $stdout and $stderr" do
      shexec = Shexec::Executor.new
      expect($stdout).to receive(:write).with("Hello, world!\n")
      shexec.run("echo", "Hello,", "world!")

      expect($stderr).to receive(:write).with(match(/No such file or directory/))
      shexec.run("cat", '/nosuch\file/or\directory')
    end

    it "does not pipe the caller's stdin into the command" do
      stdin_r, stdin_w = IO.pipe
      $stdin.reopen(stdin_r)
      stdin_w.puts "Hello, world!\n"
      stdin_w.close

      expect($stdout).to_not receive(:write).with("Hello, world!\n")
      shexec = Shexec::Executor.new
      shexec.run("cat")
    end

  end

end
