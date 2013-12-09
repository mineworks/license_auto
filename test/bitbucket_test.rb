require 'minitest/spec'
require 'minitest/autorun'
require_relative '../conf/config'
require_relative '../lib/api'

describe 'Bitbucket Test' do
  it "Can detect license info from Bitbucket" do
    url = 'https://bitbucket.org/micfan/ffplayer'
    b = API::Bitbucket.new(url)
    last_hash = b.last_commits

    last_hash.wont_be_nil

    license_info = b.get_license_info

    $plog.debug(license_info)

    license_info[:license].wont_be_nil
  end
end