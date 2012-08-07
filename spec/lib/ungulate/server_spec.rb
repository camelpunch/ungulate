require 'spec_helper'
require 'ungulate/server'

describe Ungulate::Server do
  subject do
    Ungulate::Server.new(:job_processor => processor, :queue => queue,
                         :logger => ::Logger.new(nil))
  end

  let(:processor) { double 'job processor', :process => nil }
  let(:queue_name) { 'queuename' }
  let(:queue) { double 'queue', :name => 'Some Queue', :receive => message }
  let(:message) { double 'message', :to_s => '', :delete => nil }

  it "processes messages with the provided processor" do
    message.stub(:to_s).and_return('job description')
    processor.should_receive(:process).with('job description')

    subject.run
  end

  it "deletes messages after processing" do
    processor.stub(:process).ordered
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
