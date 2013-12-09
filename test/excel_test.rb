require 'minitest/spec'
require 'minitest/autorun'
require_relative '../conf/config'
require_relative '../lib/api'

describe 'Export to Excel Test' do
  it "Can Export Product: foo" do
    exporter = API::ExcelExport.new
    release_name = 'foo'
    release_version = '1.5'
    name = 'bar'
    exporter.get_excel_by_product(name, release_name, release_version)
  end
end