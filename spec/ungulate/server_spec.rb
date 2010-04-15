require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'ungulate/server'

module Ungulate
  describe Server do
    describe "run" do
      before do
        @versions = {
          :thumb => [ :resize_to_fit, 100, 200 ],
          :large => [ :resize_to_fit, 200, 300 ],
        }

        @data = mock('Data')
        @job = mock('Job', 
                    :versions => @versions,
                    :source => @data,
                    :process => nil,
                    :store => nil)

        Job.stub(:pop).and_return(@job)

        @image = mock('RMagick::Image')

        @datum = mock('Datum')
        @data_array = [@datum]

        Magick::Image.stub(:from_blob).with(@data).and_return(@data_array)
      end

      after { Ungulate::Server.run('queuename') }

      it "should pop a job from the provided queue" do
        Job.should_receive(:pop).with('queuename')
      end

      it "should process the job" do
        @job.should_receive(:process)
      end
    end
  end
end

