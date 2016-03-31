require 'anemone'

require_relative '../api/github'
require_relative '../api/pattern'
require_relative '../../lib/misc'

module API
  class GolangOrg
    attr_reader :repo_url, :protocol, :host, :owner, :repo, :ref
    # DOC:
    # repo_url: https://golang.org/x/crypto
    def initialize(repo_url, db_ref=nil)
      @golang_import_url = repo_url
      golang_doc_prefix = 'https://godoc.org/'
      @golang_doc_url = "#{golang_doc_prefix}#{repo_url.gsub(/http[s]?:\/\//, '')}"

      repo_url_pattern = API::SOURCE_URL_PATTERN[:golang_org]
      regex_group = repo_url_pattern.match(repo_url)
      @protocol = regex_group[:protocol]
      @host = regex_group[:host]
      @repo = regex_group[:repo]
      @owner =  regex_group[:owner].nil? ? "go-#{@repo}" : regex_group[:owner]
      @ref = nil

      @http_option = {}
      http_proxy = Misc.get_http_proxy
      if http_proxy
        @http_option[:proxy_host] = http_proxy[:addr]
        @http_option[:proxy_port] = http_proxy[:port]
      end
      @repo_url = get_repo_url
    end

    def get_repo_url
      opts = {:discard_page_bodies => true, :depth_limit => 0}.merge(@http_option)
      Anemone.crawl(@golang_doc_url, opts) do |anemone|
        anemone.on_every_page do |page|
          # $plog.debug(page.body)
          xpath = "//div[@id='x-projnav']/a[1]"
          target_link = page.doc.xpath(xpath)
          if target_link.size == 0
            raise "last_commit error: #{self}, #{@repo_url}"
          else
            # short_sha = target_link.text()
            href = target_link.attr('href').value
            @repo_url = href
          end
        end
      end
      $plog.debug("@golang_import_url: #{@golang_import_url}, @repo_url: #{@repo_url}")
      @repo_url
    end

  end
end

if __FILE__ == $0
  url = 'https://google.golang.org/cloud/compute'
  url = 'https://golang.org/x/crypto'
  g = API::GolangOrg.new(url)
end


