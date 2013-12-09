require 'minitest/spec'
require 'minitest/autorun'

require_relative '../config/config'
require_relative '../lib/api/github'

describe 'ExtractText' do
  it "Extract right license name" do
    official = File.read('test/official_license.txt')
    pack = File.read('test/pack_license.txt')

    should_be = 'MIT'
    should_be.must_equal(should_be)
  end
end