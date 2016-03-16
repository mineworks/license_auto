require 'spec_helper'
require 'license_auto/package_manager/bundler_manager'

describe BundlerManager do
  let(:file_uri) { 'spec/spec_helper.rb'}
  it 'can be newed' do
    bm = BundlerManager.new(file_uri)
    expect(bm).to be_instance_of(BundlerManager)
  end

end