require 'spec_helper'
require 'license_auto/package_manager'

describe LicenseAuto::PackageManager do
  before do
    stub_get(http_uri).
        to_return(:status => 200, :body => fixture(http_uri), :headers => {})
  end

  let(:file_uri) { 'spec/spec_helper.rb'}
  let(:http_uri) { 'https://www.kernel.org/pub/site/README'}

  it 'Open file system URI' do
    pm = LicenseAuto::PackageManager.new(file_uri)
    expect(pm.raw_contents).to_not be(nil)
  end

  it 'Open HTTP URI' do
    pm = LicenseAuto::PackageManager.new(http_uri)
    expect(pm.raw_contents).to_not be(nil)
  end
end