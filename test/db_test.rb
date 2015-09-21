require 'minitest/spec'
require 'minitest/autorun'
require_relative '../conf/config'
require_relative '../lib/db'

describe 'DBTest' do
  it "Can connect to & query from DB" do
    r = $conn.exec('select * from pack')
    (r.ntuples > 0).must_equal(true)
    # puts r
    # puts r.ntuples
    # puts r[0]
    # puts r[0]['id']
  end

  it "Can get some case from DB" do
    r = get_cases
    (r.ntuples > 0).must_equal(true)
    # puts r
    # puts r.ntuples
    # puts r[0]
    # puts r[0]['id']
  end


end