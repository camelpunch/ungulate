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
    "spec/spec_helper.rb",
    "spec/ungulate/file_upload_spec.rb",
    "spec/ungulate/job_spec.rb",
    "spec/ungulate/server_spec.rb",
    "spec/ungulate/view_helpers_spec.rb"
  ]

  gem.add_runtime_dependency('activesupport', [">= 2.3.5"])
  gem.add_runtime_dependency('right_aws', [">= 2.0.0"])
  gem.add_runtime_dependency('rmagick', [">= 2.13.1"])
  gem.add_runtime_dependency('mime-types', [">= 1.16"])
  gem.add_development_dependency('rake')
  gem.add_development_dependency('rspec', [">= 2.4.0"])
  gem.add_development_dependency('cucumber', [">= 0.10.0"])
  gem.add_development_dependency('i18n', [">= 0.5.0"])
  gem.add_development_dependency('ruby-debug')
end

