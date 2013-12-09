require 'json'
require 'rspec'
require 'webmock/rspec'

require 'license_auto'


# Disable WebMock (all adapters)
# WebMock.disable!

def stub_get(url)
  stub_request(:get, url)
end

def stub_post(url)
  stub_request(:post, url)
end

def fixture_path
  File.expand_path('../fixtures', __FILE__)
end

def fixture(file)
  file = file.gsub(/^http[s]?(:\/\/)/, '')
  File.new(fixture_path + '/' + file)
end

def test_case_dir(sub_dir)
  test_case_dir = 'spec/fixtures/github.com/mineworks/license_auto_test_case'
  [test_case_dir, sub_dir].join('/')
end