require 'spec_helper'

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

  it "does not perturb $?" do
    system("true")
    expect { subject.run("true") }.to_not change { $?.pid }
  end

end