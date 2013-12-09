require 'spec_helper'
require 'hashie/mash'
require 'license_auto/website/github_com'

describe GithubCom do
  let(:my_pack) { Hashie::Mash.new(JSON.parse(File.read(fixture_path + '/' + 'my_packages/ruby_bundler.json')))}
  let(:user) {'bundler'}
  let(:repo) {'bundler'}
  let(:endpoint) { 'api.github.com'}
  let(:body)   { fixture('repos/repos.json') }
  let(:status) { 200 }

  before do
    tags_url = "https://api.github.com/repos/bundler/bundler/tags"
    stub_request(:get, tags_url).
        to_return(:status => 200, :body => fixture(tags_url), :headers => {})

    contents_path = "api.github.com/repos/bundler/bundler/contents/v1.11.2"
    stub_request(:get, "https://api.github.com/repos/bundler/bundler/contents/?ref=v1.11.2").
        to_return(:status => 200, :body => fixture(contents_path), :headers => {})

    languages_path = "https://api.github.com/repos/bundler/bundler/languages"
    stub_request(:get, languages_path).
        to_return(:status => 200, :body => fixture(languages_path), :headers => {})
  end

  it 'Get Github LicenseInfo' do
    github = GithubCom.new(my_pack, user, repo)
    license_info = github.get_license_info
    expect(license_info.licenses.size > 0).to be(true)
    # puts license_info.licenses
  end

  it 'List Github Repo languages' do
    github = GithubCom.new(my_pack, user, repo)
    languages = github.list_languages
    expect(languages.size > 0).to be(true)
  end

end
