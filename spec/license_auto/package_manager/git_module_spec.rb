require 'spec_helper'
require 'license_auto/package_manager/git_module'

describe LicenseAuto::GitModule do

  let(:repo_dir) { test_case_dir(".")}

  let(:target_modules) {
    [{:dep_file=>"spec/fixtures/github.com/mineworks/license_auto_test_case/./.gitmodules",
      :deps=>[{
                  :name=>"deps/ohnogit",
                  :path=>"deps/ohnogit",
                  :url=>"https://github.com/github/ohnogit.git",
                  :version=>"ce052f4d0cd3f33759dd6f7fd12f5e24bde84309",
                  #:branch=>nil,
                  :remote=>"https://github.com/github/ohnogit"
              }]}]
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