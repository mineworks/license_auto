require 'spec_helper'
require 'license_auto/repo'

describe LicenseAuto::Repo do
  before do
    WebMock.disable!
  end

  let(:gems_repo) { JSON.parse(File.read(fixture_path + '/' + 'my_repos/gems.json'))}
  let(:license_auto_repo) { JSON.parse(File.read(fixture_path + '/' + 'my_repos/license_auto.json'))}

  it "get dependencies of Repo: LicenseAuto" do
    repo = LicenseAuto::Repo.new(license_auto_repo)
    dependencies = repo.find_dependencies
    expect(dependencies.empty?).to be(false)
    expect(dependencies["LicenseAuto::Bundler"].empty?).to be(false)
    expect(dependencies["LicenseAuto::Bundler"].first.fetch(:deps).empty?).to be(false)

    expect(dependencies["LicenseAuto::Npm"].first.fetch(:deps).empty?).to be(false)
  end

  # TODO:
  # it "get dependencies of Repo: Gems" do
  #   repo = LicenseAuto::Repo.new(gems_repo)
  #   dependencies = repo.find_dependencies
  #   expect(dependencies.empty?).to be(false)
  #   LicenseAuto.logger.debug(JSON.pretty_generate(dependencies))
  # end
end