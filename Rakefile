# require 'rubygems'
require 'bundler'

require 'rake'

require 'rspec/core'
require 'rspec/core/rake_task'


Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |spec|
  # do not run integration tests, doesn't work on TravisCI
  spec.pattern = FileList['spec/license_auto/*_spec.rb']
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task default: [:rubocop, :spec]
