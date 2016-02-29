require 'rest-client'
require "singleton"








uri = 'http://localhost:9292/api/releases'
response = RestClient.get(uri)
p response.code
p response.cookies
p response.headers
p response.to_str