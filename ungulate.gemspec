# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ungulate}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andrew Bruce"]
  s.date = %q{2010-04-15}
  s.default_executable = %q{ungulate_server.rb}
  s.description = %q{WIP}
  s.email = %q{andrew@camelpunch.com}
  s.executables = ["ungulate_server.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/ungulate_server.rb",
     "features/camels.jpg",
     "features/cope_with_empty_queue.feature",
     "features/image_resize.feature",
     "features/step_definitions/command_steps.rb",
     "features/step_definitions/queue_steps.rb",
     "features/step_definitions/version_steps.rb",
     "features/support.rb",
     "lib/ungulate.rb",
     "lib/ungulate/file_upload.rb",
     "lib/ungulate/job.rb",
     "lib/ungulate/server.rb",
     "lib/ungulate/view_helpers.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "spec/ungulate/file_upload_spec.rb",
     "spec/ungulate/job_spec.rb",
     "spec/ungulate/server_spec.rb",
     "spec/ungulate/view_helpers_spec.rb",
     "ungulate.gemspec"
  ]
  s.homepage = %q{http://github.com/camelpunch/ungulate}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Process images using Amazon SQS and S3}
  s.test_files = [
    "spec/spec_helper.rb",
     "spec/ungulate/file_upload_spec.rb",
     "spec/ungulate/job_spec.rb",
     "spec/ungulate/server_spec.rb",
     "spec/ungulate/view_helpers_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.3.5"])
      s.add_runtime_dependency(%q<right_aws>, [">= 1.10.0"])
      s.add_runtime_dependency(%q<rmagick>, [">= 2.12.2"])
      s.add_runtime_dependency(%q<mime-types>, [">= 1.16"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_development_dependency(%q<cucumber>, [">= 0.6.2"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.3.5"])
      s.add_dependency(%q<right_aws>, [">= 1.10.0"])
      s.add_dependency(%q<rmagick>, [">= 2.12.2"])
      s.add_dependency(%q<mime-types>, [">= 1.16"])
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_dependency(%q<cucumber>, [">= 0.6.2"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.3.5"])
    s.add_dependency(%q<right_aws>, [">= 1.10.0"])
    s.add_dependency(%q<rmagick>, [">= 2.12.2"])
    s.add_dependency(%q<mime-types>, [">= 1.16"])
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
    s.add_dependency(%q<cucumber>, [">= 0.6.2"])
  end
end

