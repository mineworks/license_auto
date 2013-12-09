require 'spec_helper'
require 'license_auto/package_manager/golang'

describe LicenseAuto::Npm do
  let(:repo_dir) { 'spec/fixtures/golang.org/hello_world'}
  let(:target) {[{:dep_file=>nil, :deps=>["github.com/astaxie/beego"]}]}

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