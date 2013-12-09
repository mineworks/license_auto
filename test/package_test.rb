require 'minitest/spec'
require 'minitest/autorun'

require 'license_auto'


describe 'Check License Info of a given package(library)' do
  it "it can get license information from http://rubygems.org" do

    package = {
        language: 'Ruby',                # Ruby|Golang|Java|NodeJS|Erlang|Python|
        name: 'bundler',
        group: 'com.google.http-client', # Optional: Assign nil if your package is not a Java
        version: '1.11.2',               # Optional: Assign nil if check the latest
        project_server: 'rubygems.org'   # Optional: github.com|rubygems.org|pypi.python.org/pypi|registry.npmjs.org
    }
    auto_package = LicenseAuto::Package.new(package)
    license_info = auto.get_license_info(package)
    license_info.must_equal(package)
  end
end


