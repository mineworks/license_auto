require 'spec_helper'
require 'license_auto/package_manager/npm'

describe LicenseAuto::Npm do
  let(:repo_dir) { 'spec/fixtures/rubygems.org/hello_world'}
  # it 'can be initialed' do
  #   pm = LicenseAuto::Npm.new(repo_dir)
  #   expect(pm).to be_instance_of(LicenseAuto::Npm)
  #
  #   expect(pm.dependency_file_path_names).to_not eq([])
  #   expect(pm.dependency_file_path_names).to be_instance_of(Array)
  #
  #   expect(pm.parse_dependencies.size).to be > 0
  # end

  # it 'check system tool' do
  #   bool = LicenseAuto::Npm.check_cli
  #   expect(bool).to eq(true)
  # end
  #
  # it 'valid a sem-version' do
  #   valid_semver = '1.2.3'
  #
  #   bool = LicenseAuto::Npm.is_valid_semver?(valid_semver)
  #   expect(bool).to eq(true)
  #
  #   invalid_semver = 'a.b.c'
  #   bool = LicenseAuto::Npm.is_valid_semver?(invalid_semver)
  #   expect(bool).to eq(false)
  #
  # end

end