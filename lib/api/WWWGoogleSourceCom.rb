require 'anemone'

require_relative '../api/pattern'

module API
  class GoogleSourceCom
    attr_reader :repo_url, :protocol, :host, :owner, :repo, :ref

    # repo_url: https://go.googlesource.com/crypto
    def initialize(repo_url, db_ref=nil)
      @repo_url = repo_url

      repo_url_pattern = API::SOURCE_URL_PATTERN[:git_kernel_org]
      regex_group = repo_url_pattern.match(repo_url)
      @protocol = regex_group[:protocol]
      @host = regex_group[:host]
      @owner = regex_group[:owner]
      @repo = regex_group[:repo]

      @http_option = {}
      @ref = db_ref

    end

    # URL.
    def last_commits
      last_commit = nil
      opts = {:discard_page_bodies => true, :depth_limit => 0}
      commit_page = "#{@repo_url}/commit"
      Anemone.crawl(commit_page, opts) do |anemone|
        anemone.on_every_page do |page|
          xpath = "//table[@class='commit-info']/tr[3]/td[@class='sha1']/a[1]"
          target_link = page.doc.xpath(xpath)
          if target_link.size == 0
            raise "last_commit error: #{slef}, #{@repo_url}"
          else
            # full_href = text.attr('href')
            sha = target_link.text()
            last_commit = {
              'sha' => sha
            }
          end
        end
      end
      last_commit
    end
  end
end


if __FILE__ == $0
  url = ''
  g = API::WWWGoogleSourceCom.new(url)
  p g.last_commits
  # p g.protocol
  # p g.host
  # p g.owner
  # p g.repo
end