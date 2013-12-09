require 'httparty'
require 'nokogiri'
require_relative '../lib/misc'

# TODO: config a crontab after official site updated; or input password by hand.
class RubygemsOrgDB
  def initialize
    # @gem_conn_hash = gem_conn_hash
    @download_prefix = 'https://s3-us-west-2.amazonaws.com/rubygems-dumps/'
    http_proxy = Misc.get_http_proxy
    @http_option = {}
    if http_proxy
      @http_option[:http_proxyaddr] = http_proxy[:addr]
      @http_option[:http_proxyport] = http_proxy[:port]
    end
  end

  def find_archive_download_url()
    api_url = 'https://s3-us-west-2.amazonaws.com/rubygems-dumps/?prefix=production/public_postgresql'
    download_url = nil

    response = HTTParty.get(api_url, options=@http_option)
    if response.code == 200
      # DOC: http://www.nokogiri.org/tutorials/searching_a_xml_html_document.html#but_i_m_lazy_and_don_t_want_to_deal_with_namespaces_
      doc = Nokogiri::XML(response.body).remove_namespaces!

      xpath = "//Contents[last()]/Key/text()"
      xpath = "//Contents[last()]/Key/text()"
      text_node = doc.xpath(xpath)
      relative_url = text_node.text

      download_url = "#{@download_prefix}#{relative_url}"
    else
      raise Exception("http_status: #{response.status}")
    end
    download_url
  end

  # TODO: download function move into misc.rb or others, like launchpad.rb has the same function
  def download(url)
    file_pathname = nil
    return file_pathname
  end

  # Entry
  def upgrade_gemdata_db
    
  end

end

if __FILE__ == $0
  p RubygemsOrgDB.new.find_archive_download_url
end
