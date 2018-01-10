require 'spec_helper'
require 'tempfile'

class FascinatingTimeout < Timeout::Error; end

shared_examples "a command-with-arguments string objector" do

  it "allows commands with no arguments" do
    expect(subject.run('echo').success?).to eql true
  end

  it "allows commands with argument vectors" do
    expect(subject.run('echo', 'Hello', 'world').success?).to eql true
  end

  it "does not allow commands with arguments in a single string" do
    expect { subject.run('echo Hello world') }.to raise_error Errno::ENOENT
  end

end

shared_examples "a tainted argument objector" do

  it "raises a SecurityError if the command or arguments contain tainted strings" do
    expect { subject.run('cat; rm -rf /tmp/nosuch\file/or\directory'.taint) }.to raise_error SecurityError
    expect { subject.run('cat', '/tmp/tmp.Xm48jh3/../../etc/shadow'.taint) }.to raise_error SecurityError
  end

end

shared_examples "a process disconnected from the caller's stdin" do

  it "does not pipe the caller's stdin into the command" do
    caller_stdin, _ = IO.pipe
    expect(caller_stdin).to_not receive(:close)
    expect(caller_stdin).to_not receive(:read)
    $stdin.reopen(caller_stdin)

    subject.run("cat")
  end

end

shared_examples "a stdout and stderr streamer" do

  it "streams the command's stdout to the instance's stdout stream" do
    subject.run("echo", "Hello,", "world!")

    expect(stdout.string).to eql "Hello, world!\n"
  end

  it "streams the command's stderr to the instance's stderr stream" do
    subject.run("cat", '/nosuch\file/or\directory')

    expect(stderr.string).to match(/No such file or directory/)
  end

end

shared_examples "an optionally non-blocking executor" do

  it "can be run in non-blocking mode" do
    subject.run("cat") do |t|
      while t.alive?
        $stderr.puts "    ...doing something interesting while we wait for the process to complete"
        sleep(0.01)
      end
    end
  end

end

shared_examples "a provider of process status" do

  it "returns the Process::Status of the command if it completes with a zero exit status" do
    expect(subject.run("true").success?).to eql true
  end

  it "returns the Process::Status of the command if it completes with a non-zero exit status" do
    expect(subject.run("false").success?).to eql false
  end

  it "returns the Process::Status of the command if it is killed by signal" do
    exit_status = subject.run("sleep", "300") do |t|
      Process.kill("TERM", t.pid)
    end
    expect(exit_status.signaled?).to eql true
  end

  it "raises Errno::ENOENT if the command cannot be found" do
    expect { subject.run('/nosuch\file/or\directory') }.to raise_error Errno::ENOENT
  end

  it "raises Errno::ENOENT if the command is a script with an interpreter that cannot be found" do
    Tempfile.open('shexec') do |f|
      f.chmod(0700)
      f.write('#!/nosuch\file/or\directory')
      f.close
      expect { subject.run(f.path.untaint) }.to raise_error Errno::ENOENT
    end
  end

  it "raises Errno::EACCES if the command is not executable" do
    Tempfile.open('shexec') do |f|
      expect { subject.run(f.path.untaint) }.to raise_error Errno::EACCES
    end
  end

  it "raises Errno::EACCES if the command is a script with an interpreter that is not executable" do
    Tempfile.open('shexec-shebang') do |x|
      x.write("#!/bin/sh\nexit 0\n")
      x.close
      Tempfile.open('shexec') do |f|
        f.chmod(0700)
        f.write("#!#{x.path}")
        f.close
        expect { subject.run(f.path.untaint) }.to raise_error Errno::EACCES
      end
    end
  end

  it "does not perturb $?" do
    system("true")
    expect { subject.run("true") }.to_not change { $?.pid }
  end

end

shared_examples_for "an optionally time-limiting executor" do

  it "raises Timeout::Error if the command exceeds the specified timeout" do
    expect { subject.timeout(0.01).run("sleep", "300") }.to raise_error Timeout::Error
  end

  it "can optionally raise a specified timeout exception instead of Timeout::Error" do
    expect { subject.timeout(0.01, FascinatingTimeout).run("sleep", "300") }.to raise_error FascinatingTimeout
  end

  it "does not interrupt the command if it completes within the timeout" do
    expect(subject.timeout(300).run("cat").exitstatus).to eql 0
  end

  it "supports non-blocking mode" do
    nonblocking = false
    expect { subject.timeout(300).run("cat") { |t| nonblocking = true } }.to change { nonblocking }
  end

end
