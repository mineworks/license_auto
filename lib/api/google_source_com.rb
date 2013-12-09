require 'anemone'

require_relative '../api/pattern'
require_relative '../../lib/misc'

module API
  class GoogleSourceCom
    attr_reader :repo_url, :protocol, :host, :owner, :repo, :ref

    # repo_url: https://go.googlesource.com/crypto
    def initialize(repo_url, db_ref=nil)
      @repo_url = repo_url

      repo_url_pattern = API::SOURCE_URL_PATTERN[:google_source_com]
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

    # URL.
    def last_commits
      last_commit = nil
      opts = {:discard_page_bodies => true, :depth_limit => 0}.merge(@http_option)
      commit_page = "#{@repo_url}/commit"
      Anemone.crawl(commit_page, opts) do |anemone|
        anemone.on_every_page do |page|
p page.doc
p page.html
          xpath = "//ol[@class='CommitLog']/li[1]/a[1]"
          xpath = "//div[@class='RepoShortlog']"
          target_link = page.doc.xpath(xpath)
          p target_link
          if target_link.size == 0
            raise "last_commit error: #{self}, #{@repo_url}"
          else
            # full_href = text.attr('href')
            short_sha = target_link.text()
            full_sha = target_link.attr('href')
            last_commit = {
              'sha' => full_sha.split('/+/').last
            }
          end
        end
      end
      last_commit
    end
  end
end


if __FILE__ == $0
  url = 'https://go.googlesource.com/crypto'
  g = API::GoogleSourceCom.new(url)
   p g.last_commits
#   p g.protocol
#   p g.host
#   p g.owner
#   p g.repo
#   p g.repo_url
end
