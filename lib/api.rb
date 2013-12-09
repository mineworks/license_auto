require_relative 'api/github'
require_relative 'api/git_kernel_org'
require_relative 'api/google_source_com'
require_relative 'api/go_pkg_in'
require_relative 'api/excel_export'
require_relative 'api/bitbucket'
require_relative 'api/mq'
require_relative 'api/spider'
require_relative 'api/remote_source_package'
require_relative 'api/npm_registry'

module API
  # TODO: golang.org/net ...
  class RemoteSourceVCS
    attr_reader :vcs, :url
    def initialize(url)
      @url = url
      @vcs = nil
      if url =~ API::SOURCE_URL_PATTERN[:github]
        @vcs = API::Github.new(url)
      elsif url =~ API::SOURCE_URL_PATTERN[:git_kernel_org]
        @vcs = API::GitKernelOrg.new(url)
      elsif url =~ API::SOURCE_URL_PATTERN[:bitbucket]
        @vcs = API::Bitbucket.new(url)
      elsif url =~ API::SOURCE_URL_PATTERN[:google_source_com]
        @vcs = API::GoogleSourceCom.new(url)
      elsif url =~ API::SOURCE_URL_PATTERN[:go_pkg_in]
        @vcs = API::GoPkgIn.new(url)
      else
        @vcs = nil
        # raise "Unknown repostory: #{url}"
      end
    end

    def get_last_commit
      @vcs.last_commits
    end

    def get_homepage
      homepage = nil
      if @vcs.class == API::GoPkgIn
        homepage = @url
      end
      homepage
    end
  end
end
