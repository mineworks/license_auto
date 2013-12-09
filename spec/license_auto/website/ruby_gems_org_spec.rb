require 'spec_helper'

describe LicenseAuto::Package do
  before do
    bundler_yaml = "https://rubygems.org/api/v1/gems/bundler.yaml"
    stub_request(:get, bundler_yaml).
        to_return(:status => 200, :body => fixture(bundler_yaml), :headers => {})

    # TODO: Can this two mocked stub be included from github_helper?
    tags_url = "https://api.github.com/repos/bundler/bundler/tags"
    stub_request(:get, tags_url).
        to_return(:status => 200, :body => fixture(tags_url), :headers => {})

    contents_path = "api.github.com/repos/bundler/bundler/contents/v1.11.2"
    stub_request(:get, "https://api.github.com/repos/bundler/bundler/contents/?ref=v1.11.2").
        to_return(:status => 200, :body => fixture(contents_path), :headers => {})

    blobs_url = "https://api.github.com/repos/bundler/bundler/git/blobs/e356f59f949264bff1600af3476d5e37147957cc"
    stub_request(:get, blobs_url).
        with(:headers => {'Accept'=>'application/vnd.github.v3+json,application/vnd.github.beta+json;q=0.5,application/json;q=0.1', 'Accept-Charset'=>'utf-8', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Github API Ruby Gem 0.13.1'}).
        to_return(:status => 200, :body => fixture(blobs_url), :headers => {})

    blobs_url2 = "https://api.github.com/repos/bundler/bundler/git/blobs/c46767306718fbbb1320d43f6b5668a950c6b0d7"
    stub_request(:get, blobs_url2).
        with(:headers => {'Accept'=>'application/vnd.github.v3+json,application/vnd.github.beta+json;q=0.5,application/json;q=0.1', 'Accept-Charset'=>'utf-8', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Github API Ruby Gem 0.13.1'}).
        to_return(:status => 200, :body => fixture(blobs_url2), :headers => {})
  end

  let(:my_pack) { JSON.parse(File.read(fixture_path + '/' + 'my_packages/ruby_bundler.json'))}

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

  # it "raise KeyError when get license information of Package" do
  #
  #   package = LicenseAuto::Package.new(my_pack)
  #   expect(package.name).to eq(my_pack['name'])
  #
  #   begin
  #     license_info = package.get_license_info
  #   rescue Exception => e
  #     expect(e.class).to eq(KeyError)
  #   end
  # end
end