require 'spec_helper'
require 'ungulate/server'

describe Ungulate::Server do
  subject do
    Ungulate::Server.new(:job_processor => processor, :queue => queue,
                         :logger => ::Logger.new(nil))
  end

  let(:processor) { double 'job processor' }
  let(:queue_name) { 'queuename' }
  let(:queue) { double 'queue', :name => 'Some Queue' }
  let(:message) { double 'message', :to_s => '' }

  it "receives a message from the provided queue and processes it with the processor" do
    queue.should_receive(:receive).ordered.and_return(message)
    message.should_receive(:to_s).and_return('job description')
    processor.should_receive(:process).with('job description').ordered
    message.should_receive(:delete).ordered

    subject.run
  end

  it "returns truthy from run if it processed something" do
    queue.stub(:receive).and_return(message)
    message.stub(:delete)
    processor.stub(:process).and_return('some value')
    subject.run.should be_true
  end

  it "returns truthy even if processor returns false, so we can get next message quickly" do
    queue.stub(:receive).and_return(message)
    message.stub(:delete)
    processor.stub(:process).and_return(false)
    subject.run.should be_true
  end

  it "returns falsey from run if there was no message" do
    queue.stub(:receive).and_return(nil)
    subject.run.should be_false
  end
end
