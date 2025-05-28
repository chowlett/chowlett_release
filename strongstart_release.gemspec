# frozen_string_literal: true

require_relative "lib/strongstart_release/version"

Gem::Specification.new do |spec|
  spec.name = "strongstart_release"
  spec.version = StrongstartRelease::VERSION
  spec.authors = ["chowlett"]
  spec.email = ["chowlett@oxbtech.com"]

  spec.summary = "Provides build and deploy rake tasks for SiTE SOURCE and GRFS."
  spec.homepage = "https://strongstart.ca"
  spec.license = nil
  spec.required_ruby_version = ">= 3.3.5"

  spec.metadata["private"] = "true"
  spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/strongstart"

  spec.metadata["source_code_uri"] = "https://github.com/strong-start/strongstart_release"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      puts "f: '#{f}'"
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile]) ||
        /\Astrongstart_release-.*\.gem/.match?(f)
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
