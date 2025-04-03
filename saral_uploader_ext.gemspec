require_relative "lib/saral_uploader_ext/version"

Gem::Specification.new do |spec|
  spec.name        = "saral_uploader_ext"
  spec.version     = SaralUploaderExt::VERSION
  spec.authors     = ["Chitranshoo Prakash"]
  spec.email       = ["chitranshoo.prakash@jarvis.consulting"]
  spec.homepage    = "https://github.com/jarvisconsulting/saral-uploader-ext.git"
  spec.summary     = "Uploading files using signed URL in google cloud storage"
  spec.description = "Uploading files using signed URL in google cloud storage"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jarvisconsulting/saral-uploader-ext.git"
  spec.metadata["changelog_uri"] = "https://github.com/jarvisconsulting/saral-uploader-ext.git"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.6"
  spec.add_dependency "google-cloud-storage"
  spec.add_dependency "mime-types"

  spec.post_install_message = "Thanks for installing saral-uploader-ext. Please set environment variable mentioned in README.md"
end
