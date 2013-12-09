require 'spec_helper'
require 'hashie/mash'
require 'license_auto/website/maven_central_repository'

describe LicenseAuto::MavenCentralRepository do
  # One license
  let(:pack_a) {
    # {:group=>"net.sourceforge.nekohtml", :name=>"nekohtml", :version=>"1.9.20"}
    JSON.parse(File.read(fixture_path + '/' + 'my_packages/java_maven_one_license.json'))
  }

  # Two license
  # let(:pack_b) {
  #   {:group=>"org.cryptacular", :name=>"cryptacular", :version=>"1.0"}
  # }

  # License in comments
  # let(:pack_c) {
  #   {:group=>"commons-io", :name=>"commons-io", :version=>"2.4"}
  # }

  before do
    stub_request(:get, "http://search.maven.org/solrsearch/select?core=gav&q=g:%22net.sourceforge.nekohtml%22%20AND%20a:%22nekohtml%22%20AND%20v:%221.9.20%22&rows=20&wt=json").
        to_return(:status => 200, :body => fixture('search.maven.org/solrsearch/select/net.sourceforge.nekohtml'), :headers => {})

    pom_url = "https://repo1.maven.org/maven2/net/sourceforge/nekohtml/nekohtml/1.9.20/nekohtml-1.9.20.pom"
    stub_request(:get, pom_url).
        to_return(:status => 200, :body => fixture(pom_url), :headers => {})

    apache_20 = "http://www.apache.org/licenses/LICENSE-2.0.txt"
    stub_request(:get, apache_20).
        to_return(:status => 200, :body => fixture(apache_20), :headers => {})
  end


  it "get license information of maven package" do

    pack = pack_a
    package = LicenseAuto::Package.new(pack)
    expect(package.name).to eq(pack['name'])

    license_info = package.get_license_info
    expect(license_info).to be_a(LicenseAuto::LicenseInfoWrapper)
    unless license_info.nil?
      expect(license_info.pack).to be_a(LicenseAuto::PackWrapper)
    end

    LicenseAuto.logger.debug(JSON.pretty_generate(license_info))
  end

end
