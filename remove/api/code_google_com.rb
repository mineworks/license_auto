require 'anemone'
require_relative '../api/pattern'
require_relative '../../lib/misc'

module API
  class CodeGoogleCom
    attr_reader :repo_url, :protocol, :host, :owner, :repo, :ref

    # repo_url: https://code.google.com/p/go-uuid/
    def initialize(repo_url, db_ref=nil)
      @repo_url = repo_url

      repo_url_pattern = API::SOURCE_URL_PATTERN[:code_google_com]
      regex_group = repo_url_pattern.match(repo_url)
      @protocol = regex_group[:protocol]
      @host = regex_group[:host]
      @owner = regex_group[:owner]
      @repo = regex_group[:repo]

      @http_option = {}
      http_proxy = Misc.get_http_proxy
      if http_proxy
        @http_option[:proxy_host] = http_proxy[:addr]
        @http_option[:proxy_port] = http_proxy[:port]
      end
      @ref = db_ref

    end

    # URL. https://code.google.com/p/go-uuid/source/list
    def last_commits
      last_commit = nil
      opts = {:discard_page_bodies => true, :depth_limit => 0}.merge(@http_option)
      commit_page_prefix = 'https://code.google.com/p/'
      commit_page = "#{commit_page_prefix}#{@repo}/source/list"
      Anemone.crawl(commit_page, opts) do |anemone|
        anemone.on_every_page do |page|
          xpath = "//td[@class='hexid id'][1]/a[1]"
          target_link = page.doc.xpath(xpath)
          if target_link.size == 0
            raise "last_commit error: #{self}, #{@repo_url}"
          else
            # short_sha = target_link.text()
            full_sha = target_link.attr('href').value
            last_commit = {
              'sha' => full_sha.split('?r=').last
            }
          end
        end
      end
      last_commit
    end
  end
end

if __FILE__ == $0
  url = 'https://code.google.com/p/go-uuid/'
  c = API::CodeGoogleCom.new(url)
  p c.protocol
  p c.host
  p c.owner
  p c.repo
  p c.repo_url
  p c.last_commits

end
