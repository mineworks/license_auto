require 'minitest/spec'
require 'minitest/autorun'
require_relative '../conf/config'
require_relative '../extractor_ruby/License_recognition'

describe 'License identity Test' do
  it "Can identity a license" do
    pack_id = 3404
    pg_result = $conn.exec("select * from pack where license_text is not null")
    if pg_result.ntuples > 0
      license_text = pg_result[0]['license_text']
      license = License_recognition.new.similarity(license_text, "./extractor_ruby/Package_license")
      $plog.debug("license: #{license}, license_text: #{license_text}")
      license.wont_be_nil
    else
      $plog.debug("pack_id not found: #{pack_id}")
    end
  end
end