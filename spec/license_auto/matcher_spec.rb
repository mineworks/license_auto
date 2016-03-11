require 'spec_helper'

describe LicenseAuto::Matcher::SourceURL do
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
      matched = matcher.match_bitbucket_resource

      # expect(matched).to_not eq(nil)
    }
  end
end

describe LicenseAuto::Matcher::FilepathName do

  it 'match README files' do
    md = 'readme.md'
    txt = 'readme.txt'
    [md, txt].each {|filename|
      matcher = LicenseAuto::Matcher::FilepathName.new(filename)
      matched = matcher.match_readme_file

      expect(matched).to_not eq(nil)
      expect(matched[:extension]).to_not eq(nil)
    }

    raw = 'README'
    matcher = LicenseAuto::Matcher::FilepathName.new(raw)
    matched = matcher.match_readme_file
    expect(matched[:extension]).to eq(nil)
  end

  it 'match LICENSE files' do
    raw = 'LICENSE'
    expect(LicenseAuto::Matcher::FilepathName.new(raw).match_license_file).to_not be(nil)

    md = 'LICENSE.md'
    expect(LicenseAuto::Matcher::FilepathName.new(md).match_license_file).to_not be(nil)

    mit = 'MIT-LICENSE.md'
    matcher = LicenseAuto::Matcher::FilepathName.new(mit)
    matched = matcher.match_license_file
    expect(matched).to_not be(nil)
    expect(matched[:license_name]).to eq('MIT')
  end

  it 'match versions' do
    # A Git tag
    git_ref = 'v4.2.5.2'
    package_version = '4.2.5.2'
    expect(LicenseAuto::Matcher::FilepathName.new(package_version).match_the_ref(git_ref)).to_not be(nil)
  end
end