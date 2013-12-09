require_relative '../api/github'

module API
  class GoPkgIn
    attr_reader :repo_url, :protocol, :host, :owner, :repo, :ref
    # DOC: http://labix.org/gopkg.in#SupportedURLs
    # repo_url: https://gopkg.in/validator.v2 -> https://github.com/go-validator/validator/tree/v2
    def initialize(repo_url, db_ref=nil)
      @repo_url_perfix = 'https://github.com'

      repo_url_pattern = API::SOURCE_URL_PATTERN[:go_pkg_in]
      regex_group = repo_url_pattern.match(repo_url)
      @protocol = regex_group[:protocol]
      @host = regex_group[:host]
      @repo = regex_group[:repo]
      @owner =  regex_group[:owner].nil? ? "go-#{@repo}" : regex_group[:owner]

      # TODO: follow DOC: ()branch/tag v3, v3.N, or v3.N.M)
      @ref = regex_group[:ref]
      @repo_url = "#{@repo_url_perfix}/#{@owner}/#{@repo}"
    end

    def last_commits
      g = API::Github.new(@repo_url, db_ref=@ref)
      g.last_commits
    end

  end
end

if __FILE__ == $0
  url = 'https://gopkg.in/validator.v2'
  g = API::GoPkgIn.new(url)
  p g.last_commits
  p g.protocol
  p g.host
  p g.owner
  p g.repo
  p g.ref
  p g.repo_url
end
