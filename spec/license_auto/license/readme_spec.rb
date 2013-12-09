require 'spec_helper'
require 'license_auto/package_manager'

describe LicenseAuto::VirtualPackageManager do
  before do
    stub_get(readme_uri).
        to_return(:status => 200, :body => fixture(http_uri), :headers => {})
  end

  let(:file_uri) { 'spec/spec_helper.rb'}
  let(:readme_uri) { 'https://www.kernel.org/pub/site/README'}
end