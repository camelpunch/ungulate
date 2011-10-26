require 'spec_helper'
require 'ungulate/server'

module Ungulate
  describe Server do
    let(:job) { double 'job' }
    let(:queue_name) { 'queuename' }

    shared_examples_for "an ungulate server" do
      it "pops a job from the provided queue and processes it" do
        Job.should_receive(:pop).with(queue_name).and_return(job)
        job.should_receive(:process)
        Server.run queue_name
      end
    end

    it_behaves_like "an ungulate server"

    context "with a different queue name" do
      let(:queue_name) { 'otherqueuename' }
      it_behaves_like "an ungulate server"
    end
  end
end
