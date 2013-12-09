require 'rubygems'
require 'rubygems/remote_fetcher'
require 'rubygems/spec_fetcher'
require 'rubygems/dependency'


class RubyGemsOrg < Website


  GIT_HASH_LENGTH = 40

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
      github = Github.new(user: github_matched[:owner], repo: github_matched[:repo])
      possible_ref = nil
      if @package.version.size >= GIT_HASH_LENGTH
                        # Golang version is a Git SHA
        possible_ref = @package.version
      else
        matcher = LicenseAuto::Matcher::FilepathName.new(@package.version)
        github.repos.tags do |tag|
          puts tag.name

          matched = matcher.match_the_ref(tag.name)
          if matched
            possible_ref = tag.name
            break
          end
        end
      end
      # TODO: @Cissy, uncomment it, get the default branch name
      # possible_ref = github.default_branch if possible_ref.nil?

      contents = github.repos.contents.get(path: '/', ref: possible_ref)


      # puts contents.inspect
      license_files = []
      readme_files = []
      contents.each {|obj|
        if obj.type == 'file'
          filename_matcher = LicenseAuto::Matcher::FilepathName.new(obj.name)
          license_files.push(obj) if filename_matcher.match_license_file
          readme_files.push(obj) if filename_matcher.match_readme_file
          notice_files.push(obj) if filename_matcher.match_notice_file
        end
      }

      if license_files.any?
        return LicenseAuto::LicenseInfo.new(license_files)
      end

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