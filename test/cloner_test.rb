require 'minitest/spec'
require 'minitest/autorun'
require 'open3'


require 'git'
require_relative '../conf/config'


describe 'ClonerText' do
  it "Extract right license name" do
    pack_repo_path = './'
    g = Git.open(pack_repo_path)
    last_commit_hash = g.log(1).last.sha
    $plog.debug("last_commit_hash: #{last_commit_hash}")
    Open3.popen3('git log -1 HEAD') {|i,o,e,t|
      out = o.readline.split(' ')
      if out.length > 0
        last_commit_hash.must_equal(out[1])
      end
    }
  end
end
