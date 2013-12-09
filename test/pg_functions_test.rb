require 'minitest/spec'
require 'minitest/autorun'


require_relative '../config/config'


describe 'PGFunctionTest' do
  it "it can reinsert a package into PostgreSQL" do
    sql = "
      select add_pack(
               'foo',
               '0.1',
               'Ruby',
               'http://homepage.com',
               'http://foo.sourcecode.com',
               'MIT',
               10,
               ''
             )
    "
    # result = api_add_pack(pack_name, pack_version, 'Golang', homepage, pack_url, status, cmt)
    result = $conn.exec(sql)
    (result.ntuples == 1).must_equal(true)
  end
end


