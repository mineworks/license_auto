require 'spec_helper'
require 'license_auto/package_manager/golang'

describe LicenseAuto::Golang do
  let(:repo_dir) { 'spec/fixtures/golang.org/hello_world'}
  let(:target) {
    [
        {
            :dep_file=>nil,
            :deps=> [
                {:name=>"beego",
                :version=>"88c5dfa6ead42e624c2e7d9e04eab6cb2d07412a",
                :remote=>"https://github.com/astaxie/beego"}
              ]
        }
    ]
  }

  before do
    commit_url = "https://api.github.com/repos/astaxie/beego/commits"
    stub_request(:get, commit_url).
        to_return(:status => 200, :body => fixture(commit_url), :headers => {})
  end


  it 'check system tool' do
    bool = LicenseAuto::Golang.check_cli
    expect(bool).to eq(true)
  end

  it 'got Golang dependencies' do
    pm = LicenseAuto::Golang.new(repo_dir)
    deps = pm.parse_dependencies
    expect(deps).to eq(target)
  end

end