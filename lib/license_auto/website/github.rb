require 'github_api'

module LicenseAuto

  ##
  #
  # @owner: string
  # @repo:  string
  # @pack_version: string
  #
  # @return LicenseInfo
  GIT_HASH_LENGTH = 40

  def self.github_get_license_info(owner, repo, package_version=nil)
    github = Github.new(user: owner, repo: repo)

    possible_ref = nil
    # If provided a Git SHA, use it directly
    if package_version.size >= GIT_HASH_LENGTH
      possible_ref = package_version
    else
      matcher = LicenseAuto::Matcher::FilepathName.new(package_version)
      github.repos.tags do |tag|
        matched = matcher.match_the_ref(tag.name)
        if matched
          possible_ref = tag.name
          break
        end
      end
    end

    # If possible_ref is nil, the Github API server will return the default branch contents
    contents = github.repos.contents.get(path: '/', ref: possible_ref)

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
end
