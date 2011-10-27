require 'ungulate'
require 'rspec'

RSpec.configure do |config|
  def fixture_path(filename)
    File.expand_path("fixtures/#{filename}", File.dirname(__FILE__))
  end

  def fixture(filename)
    File.read fixture_path(filename)
  end

  def clear(queue)
    puts "CLEAR"
    (1..240).each do
      queue.clear
      size = queue.size
      puts "queue size: #{size}"
      return if size.zero?
      sleep 1
      puts "slept 1 second"
    end
    queue.size.should be_zero
  end

  def wait_for_non_empty(queue)
    puts "WAIT FOR NON EMPTY"
    (1..240).each do
      size = queue.size
      puts "queue size: #{size}"
      return if size > 0
      sleep 1
      puts "slept 1 second"
    end
    queue.size.should_not be_zero
  end

  shared_examples_for "a message queue" do
    it "has a name" do
      new_queue.name.should be_present
    end

    it "can send and receive one message at a time" do
      queue = new_queue
      clear(queue)

      sent_bodies = Set.new %w(hello there how are you)

      sent_bodies.each do |message|
        puts "pushing #{message}"
        queue.push(message)
      end

      queue = nil

      new_queue_instance = new_queue
      wait_for_non_empty(new_queue_instance)

      received_bodies = Set.new

      iterations = 0
      messages = []
      while (received_bodies != sent_bodies) && iterations < 30 do
        messages << new_queue_instance.receive
        bodies = messages.map(&:to_s)
        received_bodies += bodies.select(&:present?)
        iterations += 1
        puts "iteration: #{iterations} :: messages: #{received_bodies.to_a.join(',')}"
      end

      received_bodies.should == sent_bodies
    end
  end
end
