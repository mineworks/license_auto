require 'spec_helper'
require 'license_auto/package_manager/git_module'

describe LicenseAuto::GitModule do
  let(:repo_dir) { test_case_dir(nil)}
  let(:target_modules) {
    [{:dep_file=>"spec/fixtures/github.com/mineworks/license_auto_test_case/.gitmodules",
      :deps=>[{:name=>"https://github.com/github/ohnogit", :version=>nil, :remote=>"https://github.com/github/ohnogit"}]}]
  }

  let(:pm) {LicenseAuto::GitModule.new(repo_dir)}

  it 'check system tool' do
    bool = LicenseAuto::GitModule.check_cli
    expect(bool).to eq(true)
  end

  it 'parse_dependencies' do
    deps = pm.parse_dependencies
    expect(deps).to eq(target_modules)
  end

end