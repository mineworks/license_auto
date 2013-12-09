require_relative 'api/github'
require_relative 'api/git_kernel_org'
require_relative 'api/google_source_com'
require_relative 'api/code_google_com'
require_relative 'api/go_pkg_in'
require_relative 'api/golang_org'
require_relative 'api/excel_export'
require_relative 'api/bitbucket'
require_relative 'api/mq'
require_relative 'api/spider'
require_relative 'api/remote_source_package'
require_relative 'api/npm_registry'

module API
  class RemoteSourceVCS
    attr_reader :vcs, :url
    def initialize(url)
      @url = url

      if url =~ API::SOURCE_URL_PATTERN[:golang_org]
        url = API::GolangOrg.new(url).repo_url
      end
      @vcs = if url =~ API::SOURCE_URL_PATTERN[:github]
               API::Github.new(url)
             elsif url =~ API::SOURCE_URL_PATTERN[:git_kernel_org]
               API::GitKernelOrg.new(url)
             elsif url =~ API::SOURCE_URL_PATTERN[:bitbucket]
               API::Bitbucket.new(url)
             elsif url =~ API::SOURCE_URL_PATTERN[:google_source_com]
               API::GoogleSourceCom.new(url)
             elsif url =~ API::SOURCE_URL_PATTERN[:code_google_com]
               API::CodeGoogleCom.new(url)
             elsif url =~ API::SOURCE_URL_PATTERN[:go_pkg_in]
               API::GoPkgIn.new(url)
             else
               nil
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

if __FILE__ == $0
  url = 'https://google.golang.org/cloud/compute'
  r = API::RemoteSourceVCS.new(url)
  p r.get_last_commit
end
