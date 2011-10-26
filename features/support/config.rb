$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'lib/ungulate'
require 'ruby-debug'

QUEUE_NAME = 'ungulate-test-queue'
BUCKET_NAME = 'ungulate-test'
