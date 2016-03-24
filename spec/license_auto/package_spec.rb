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
  end

  let(:my_pack) { JSON.parse(File.read(fixture_path + '/' + 'my_packages/ruby_bundler.json'))}

  it "get license information of Package" do

    package = LicenseAuto::Package.new(my_pack)
    expect(package.name).to eq(my_pack['name'])

    license_info = package.get_license_info()
    expect(license_info).to be_a(LicenseAuto::LicenseInfo)

    LicenseAuto.logger.debug(JSON.pretty_generate(license_info.licenses))
  end

  it "raise KeyError when get license information of Package" do
    # my_pack = my_pack.merge({language: 'foo'})

    package = LicenseAuto::Package.new(my_pack)
    expect(package.name).to eq(my_pack['name'])

    begin
      license_info = package.get_license_info
    rescue Exception => e
      expect(e.class).to eq(KeyError)
    end
  end
end