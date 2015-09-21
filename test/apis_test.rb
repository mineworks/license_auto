require 'minitest/spec'
require 'minitest/autorun'
require_relative '../conf/config'
require_relative '../lib/api/github'

describe 'APIs Test' do
  it "Can fetch last commit of github" do
    url = 'https://github.com/micfan/dinner.git'
    g = API::Github.new(url)
    last = g.last_commits

    last_hash = last['sha']
    last_hash.wont_be_nil

    license_info = g.get_license_info
    $plog.debug(license_info)
    license_info[:license].wont_be_nil
  end
end