require 'spec_helper'
require 'license_auto/repo'

describe LicenseAuto::Repo do
  before do
    WebMock.disable!
  end

  let(:license_auto_test_branch) { JSON.parse(File.read(fixture_path + '/' + 'my_repos/license_auto_test_branch.json'))}

  it "get dependencies of Repo: LicenseAuto" do
    repo = LicenseAuto::Repo.new(license_auto_test_branch)
    dependencies = repo.find_dependencies
    expect(dependencies.empty?).to be(false)
    expect(dependencies["LicenseAuto::Bundler"].empty?).to be(false)
    expect(dependencies["LicenseAuto::Bundler"].first.fetch(:deps).empty?).to be(false)

    expect(dependencies["LicenseAuto::Npm"].first.fetch(:deps).empty?).to be(false)
  end
end