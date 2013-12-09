require 'spec_helper'
require 'license_auto/package_manager/bundler'

describe LicenseAuto::Bundler do
  let(:repo_dir) { 'spec/fixtures/rubygems.org/hello_world'}
  it 'can be initialed' do
    pm = LicenseAuto::Bundler.new(repo_dir)
    expect(pm).to be_instance_of(LicenseAuto::Bundler)

    expect(pm.dependency_file_path_names).to_not eq([])
    expect(pm.dependency_file_path_names).to be_instance_of(Array)

    expect(pm.parse_dependencies.size).to be > 0
  end

end