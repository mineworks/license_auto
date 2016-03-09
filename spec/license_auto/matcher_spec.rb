require 'spec_helper'

describe LicenseAuto::Matcher do
  let(:owner) {'mineworks'}
  let(:owner) {'mineworks'}
  let(:repo) {'license_auto'}
  let(:vcs) {'git'}

  it 'match Github resources' do
    https = 'https://github.com/mineworks/license_auto.git'
    ssh = 'git@github.com:mineworks/license_auto.git'
    html = 'https://github.com/mineworks/license_auto'
    # TODO: git = 'git://github.com/mineworks/license_auto'

    # FIXME: @Cissy
    https2 = 'https://github.com/angular/angular.js.git'

    [https, ssh, html].each {|uri|
      matcher = LicenseAuto::Matcher::SourceURL.new(uri)
      matched = matcher.match_github_resource()

      expect(matched).to_not eq(nil)
      expect(matched[:owner]).to eq(owner)
      expect(matched[:repo]).to eq(repo)
      expect(matched[:vcs]).to eq(vcs)
    }
  end

  it 'match Bitbucket resources' do
    https = 'https://micfan@bitbucket.org/micfan/worldcup.git'
    ssh = 'git@bitbucket.org:micfan/worldcup.git'
    html = 'git@bitbucket.org:micfan/worldcup.git'

    [https, ssh, html].each {|uri|
      matcher = LicenseAuto::Matcher::SourceURL.new(uri)
      matched = matcher.match_bitbucket_resource()
      # expect(matched).to_not eq(nil)
    }
  end
end