require 'spec_helper'

describe LicenseAuto::Package do
  it "get license information of Package" do
    my_pack = {
        language: 'Ruby',                # Ruby|Golang|Java|NodeJS|Erlang|Python|
        name: 'bundler',
        group: 'com.google.http-client', # Optional: Assign nil if your package is not a Java
        version: '1.11.2',               # Optional: Assign nil if check the latest
        project_server: 'rubygems.org'   # Optional: github.com|rubygems.org|pypi.python.org/pypi|registry.npmjs.org
    }
    package = LicenseAuto::Package.new(my_pack)
    expect(package.name).to eq(my_pack[:name])

    license_info = package.get_license_info()
    expect(license_info).to be_a(LicenseAuto::LicenseInfo)

    puts license_info.body
  end
end