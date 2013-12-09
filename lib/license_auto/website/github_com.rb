require 'github_api'

class GithubCom < Website

  HOST = 'github.com'
  LANGUAGE = nil

  GIT_HASH_LENGTH = 40

  ##
  # package: Hashie::Mash
  # user: string
  # repo: string
  # ref: string
  def initialize(package, user, repo, ref=nil)
    super(package)
    @ref = ref
    @server = Github.new(user: user, repo: repo)
  end

  ##
  # @return LicenseInfo

  def get_license_info()
    possible_ref = @ref || get_possible_ref
    # If possible_ref is nil, the Github API server will return the default branch contents
    contents = @server.repos.contents.get(path: '/', ref: possible_ref)

    license_files = []
    readme_files = []
    notice_files = []
    contents.each {|obj|
      if obj.type == 'file'
        filename_matcher = LicenseAuto::Matcher::FilepathName.new(obj.name)
        license_files.push(obj) if filename_matcher.match_license_file
        readme_files.push(obj) if filename_matcher.match_readme_file
        notice_files.push(obj) if filename_matcher.match_notice_file
      end
    }

    LicenseAuto::LicenseInfo.new(licenses: license_files, readmes: readme_files, notices: notice_files)
  end

  def get_possible_ref()
    possible_ref = nil
    # If provided a Git SHA, use it directly
    if @package.version.size >= GIT_HASH_LENGTH
      possible_ref = @package.version
    else
      matcher = LicenseAuto::Matcher::FilepathName.new(@package.version)
      @server.repos.tags do |tag|
        matched = matcher.match_the_ref(tag.name)
        if matched
          possible_ref = tag.name
          break
        end
      end
    end
    possible_ref
  end
end
