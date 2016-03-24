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

# def stub_patch(path, endpoint = Github.endpoint.to_s)
#   stub_request(:patch, endpoint + path)
# end
#
# def stub_put(path, endpoint = Github.endpoint.to_s)
#   stub_request(:put, endpoint + path)
# end
#
# def stub_delete(path, endpoint = Github.endpoint.to_s)
#   stub_request(:delete, endpoint + path)
# end

def fixture_path
  File.expand_path('../fixtures', __FILE__)
end

def fixture(file)
  file = file.gsub(/^http[s]?(:\/\/)/, '')
  File.new(fixture_path + '/' + file)
end