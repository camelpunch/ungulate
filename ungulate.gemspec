Gem::Specification.new do |gem|
  gem.name = 'ungulate'
  gem.version = File.read('VERSION')

  gem.authors = ["Andrew Bruce"]
  gem.date = Date.today.to_s
  gem.default_executable = 'ungulate_server.rb'
  gem.description = File.read('README.rdoc')
  gem.email = 'andrew@camelpunch.com'
  gem.executables = ["ungulate_server.rb"]
  gem.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  gem.files = Dir[
    ".document",
    ".gitignore",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/*",
    "features/**/*",
    "lib/**/*",
    "spec/**/*",
  ]
  gem.homepage = 'http://github.com/camelpunch/ungulate'
  gem.rdoc_options = ["--charset=UTF-8"]
  gem.require_paths = ["lib"]
  gem.summary = 'Process images using Amazon SQS and S3'
  gem.test_files = [
    "spec/lib/ungulate/file_upload_spec.rb",
    "spec/lib/ungulate/job_spec.rb",
    "spec/lib/ungulate/server_spec.rb",
    "spec/lib/ungulate/blob_processor_spec.rb",
    "spec/lib/ungulate/curl_http_spec.rb",
    "spec/lib/ungulate/rmagick_version_creator_spec.rb",
    "spec/lib/ungulate/s3_storage_spec.rb",
    "spec/lib/ungulate/sqs_message_queue_spec.rb",
    "spec/lib/ungulate/view_helpers_spec.rb"
  ]

  gem.add_runtime_dependency('activesupport', [">= 2.3.5"])
  gem.add_runtime_dependency('right_aws', [">= 2.0.0"])
  gem.add_runtime_dependency('rmagick', [">= 2.13.1"])
  gem.add_runtime_dependency('mime-types', [">= 1.16"])
  gem.add_runtime_dependency('curb', [">= 0.7.15"])
  gem.add_runtime_dependency('hashie', [">= 1.2.0"])
  gem.add_development_dependency('rake')
  gem.add_development_dependency('rspec', [">= 2.4.0"])
  gem.add_development_dependency('cucumber', [">= 1.1.1"])
  gem.add_development_dependency('i18n', [">= 0.5.0"])

  if RUBY_VERSION =~ /^1.9/
    gem.add_development_dependency('ruby-debug19')
  else
    gem.add_development_dependency('ruby-debug')
  end
end

