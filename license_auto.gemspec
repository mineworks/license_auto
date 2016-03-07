# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require './lib/license_auto/version'

Gem::Specification.new do |spec|
  spec.name          = "license_auto"
  spec.version       = LicenseAuto::VERSION::STRING
  spec.authors       = ['MineWorks']
  spec.email         = [""]

  spec.summary       = %q{License Automation Toolkit}
  spec.description   = %q{LicenseAuto is a library for Open Source License collection job. Supported Language Package
                          Management including:
                            Ruby Gems, Java Maven Gradle, NodeJS npm, Erlang rebar, Debian launchpad.net, Golang}

  spec.homepage      = "https://github.com/mineworks/license_auto"
  spec.license       = "MIT"

  spec.metadata = {
      'repository_url' => 'https://github.com/mineworks/license_auto.git'
  }

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
