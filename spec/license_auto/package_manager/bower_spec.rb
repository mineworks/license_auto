require 'spec_helper'
require 'license_auto/package_manager/bower'

describe LicenseAuto::Bower do

  before(:all) do
    repo_dir = test_case_dir('bower')
    @pm = LicenseAuto::Bower.new(repo_dir)
  end

  it 'check system tool' do
    bool = LicenseAuto::Bower.check_cli
    expect(bool).to eq(true)
  end

  it 'valid a sem-version' do
    valid_semver = '1.2.3'

    bool = LicenseAuto::Bower.is_valid_semver?(valid_semver)
    expect(bool).to eq(true)

    invalid_semver = 'a.b.c'
    bool = LicenseAuto::Bower.is_valid_semver?(invalid_semver)
    expect(bool).to eq(false)
  end

  it 'parse_dependencies' do
    expect(@pm.dependency_file_path_names).to_not eq([])
    expect(@pm.dependency_file_path_names).to be_instance_of(Array)

    deps = @pm.parse_dependencies
    expect(deps.size).to be > 0

    LicenseAuto.logger.debug(JSON.pretty_generate(deps))
  end

end