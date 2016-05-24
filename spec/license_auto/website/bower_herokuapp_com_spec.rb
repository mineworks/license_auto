require 'spec_helper'
require 'hashie/mash'
require 'license_auto/website/bower_herokuapp_com'

describe LicenseAuto::BowerHerokuappCom do
  let(:pack_name) {'jquery'}

  before do
    url = "http://bower.herokuapp.com/packages/jquery"
    stub_request(:get, url).
        to_return(:status => 200, :body => fixture(url), :headers => {})

    github_tags = "https://api.github.com/repos/jquery/jquery-dist/tags"
    stub_request(:get, github_tags).
        to_return(:status => 200, :body => fixture(github_tags), :headers => {})

    github_contents = "https://api.github.com/repos/jquery/jquery-dist/contents/?ref=2.2.0"
    stub_request(:get, github_contents).
        to_return(:status => 200, :body => fixture(github_contents.gsub('?ref=', '')), :headers => {})

    github_blobs = "https://api.github.com/repos/jquery/jquery-dist/git/blobs/5312a4c864d220d496ae0b6fd11834a08396fb89"
    stub_request(:get, github_blobs).
        to_return(:status => 200, :body => fixture(github_blobs), :headers => {})

    github_blobs2 = "https://api.github.com/repos/jquery/jquery-dist/git/blobs/a00f666f32bdc7561df36a4b54476237cdc5e3bf"
    stub_request(:get, github_blobs2).
        to_return(:status => 200, :body => fixture(github_blobs2), :headers => {})
  end

  let(:my_pack) { JSON.parse(File.read(fixture_path + '/' + 'my_packages/javascript_bower.json'))}

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
