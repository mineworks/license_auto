require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :default => 'test'

# gem 'rdoc'
# require 'rdoc/rdoc'
#
# options = RDoc::Options.new
# # see RDoc::Options
#
# rdoc = RDoc::RDoc.new
# rdoc.document options
# # see RDoc::RDoc