require 'spec_helper'
require 'hashie/mash'
require 'license_auto/website/npm_registry'

describe LicenseAuto::NpmRegistry do
  let(:pack_name) {'grunt'}
  let(:body)   { fixture('repos/repos.json') }

  before do
    url = "http://registry.npmjs.org/grunt"
    stub_request(:get, url).
        to_return(:status => 200, :body => fixture(url), :headers => {})

    github_tags = "https://api.github.com/repos/gruntjs/grunt/tags"
    stub_request(:get, github_tags).
        to_return(:status => 200, :body => fixture(github_tags), :headers => {})

    github_contents = "https://api.github.com/repos/gruntjs/grunt/contents/?ref=v1.0.1"
    stub_request(:get, github_contents).
        to_return(:status => 200, :body => fixture(github_contents.gsub('?ref=', '')), :headers => {})

    blobs = "https://api.github.com/repos/gruntjs/grunt/git/blobs/dcf8a0c01b35b948c1a3d80cd2279d1879914444"
    stub_request(:get, blobs).
        to_return(:status => 200, :body => fixture(blobs), :headers => {})

    blobs_1 = "https://api.github.com/repos/gruntjs/grunt/git/blobs/dcd6f65324b15cdb159c4c97e7ddfe801c0ae99b"
    stub_request(:get, blobs_1).
        to_return(:status => 200, :body => fixture(blobs_1), :headers => {})
  end

  let(:my_pack) { JSON.parse(File.read(fixture_path + '/' + 'my_packages/nodejs_npm.json'))}

  it "get license information of Package" do

    package = LicenseAuto::Package.new(my_pack)
    expect(package.name).to eq(my_pack['name'])

    license_info = package.get_license_info()
    expect(license_info).to be_a(LicenseAuto::LicenseInfoWrapper)
    unless license_info.nil?
      expect(license_info.pack).to be_a(LicenseAuto::PackWrapper)
    end

    LicenseAuto.logger.debug(JSON.pretty_generate(license_info))
  end

end
