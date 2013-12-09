require 'rubygems'
require 'rubygems/remote_fetcher'
require 'rubygems/spec_fetcher'
require 'rubygems/dependency'

require 'license_auto/website/github'


class RubyGemsOrg < Website




  def initialize(package)
    super(package)
  end

  # (Defaults to the latest version if no version is specified.)

  def get_license_info()
    if @package.version.nil?
      @package.version = get_remote_latest_version
      raise('This rubygem could not be found') unless @package.version
    end

    gem_info = get_gem_info
    gem_info = Hashie::Mash.new(gem_info)

    source_code_matcher = LicenseAuto::Matcher::SourceURL.new(gem_info.source_code_uri)

    github_matched = source_code_matcher.match_github_resource
    if github_matched
      license_info = LicenseAuto::github_get_license_info(github_matched[:owner], github_matched[:repo], @package.version)
    end

    # bitbucket_matched = source_code_matcher.match_bitbucket_resource()
    # if github_matched
    #   # TODO: bitbucket_matched
    # end
  end

  def get_gem_info()
    # TODO: Gems.info(@package.name, @package.version)
    Gems.info(@package.name)
  end

  def get_remote_latest_version()
    # TODO: An alternative, push a gem named `mine_gems`
    # versions = Gems.versions(@package.name)

    fetcher = Gem::SpecFetcher.fetcher
    dependency = Gem::Dependency.new(@package.name, ">= #{@package}")
    remotes, = fetcher.search_for_dependency dependency
    remotes  = remotes.map { |n, _| n.version }
    latest_remote = remotes.sort.last
  end

  def download_gem()
  end
end