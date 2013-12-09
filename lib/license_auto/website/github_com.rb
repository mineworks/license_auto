require 'base64'

require 'fileutils'
require 'github_api'
require 'git'


require 'license_auto/config/config'
require 'license_auto/license/similarity'
require 'license_auto/license/readme'

class GithubCom < Website

  HOST = 'github.com'
  LANGUAGE = nil

  GIT_HASH_LENGTH = 40

  attr_reader :url

  ##
  # package: Hashie::Mash
  # user: string
  # repo: string
  # ref: string
  def initialize(package, user, repo, ref=nil, auto_pagination=false)
    super(package)
    @ref = ref
    @url = "https://github.com/#{user}/#{repo}"
    LicenseAuto.logger.debug(@url)

    @server =
      begin
        eval('WebMock')
        LicenseAuto.logger.debug("Running LicenseAuto in RSpec mode")
        Github.new(user: user, repo: repo)
      rescue NameError => e
        LicenseAuto.logger.debug("Running LicenseAuto in formal mode")
        basic_auth = "#{LUTO_CONF.github.username}:#{LUTO_CONF.github.access_token}"
        Github.new(user: user, repo: repo, basic_auth: basic_auth, auto_pagination: auto_pagination)
      end
  end

  ##
  # @return LicenseInfoWrapper

  def get_license_info()
    possible_ref = @ref || match_versioned_ref
    LicenseAuto.logger.debug("possible_ref: #{possible_ref}")
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

    license_files = license_files.map {|obj|
      license_content = get_blobs(obj['sha'])
      license_name, sim_ratio = LicenseAuto::Similarity.new(license_content).most_license_sim
      LicenseAuto::LicenseWrapper.new(
        name: license_name,
        sim_ratio: sim_ratio,
        html_url: obj['html_url'],
        download_url: obj['download_url'],
        text: license_content
      )
    }

    readme_files = readme_files.map {|obj|
      readme_content = get_blobs(obj['sha'])
      license_content = LicenseAuto::Readme.new(obj['download_url'], readme_content).license_content
      LicenseAuto.logger.debug("readme_content:\n#{license_content}\n")
      if license_content.nil?
        next
      else
        license_name, sim_ratio = LicenseAuto::Similarity.new(license_content).most_license_sim
        LicenseAuto::LicenseWrapper.new(
            name: license_name,
            sim_ratio: sim_ratio,
            html_url: obj['html_url'],
            download_url: obj['download_url'],
            text: license_content
        )
      end
    }.compact

    pack_wrapper = LicenseAuto::PackWrapper.new(
        homepage: nil,
        project_url: nil,
        source_url: @url
    )
    LicenseAuto::LicenseInfoWrapper.new(
        licenses: license_files,
        readmes: readme_files,
        notices: notice_files,
        pack: pack_wrapper
    )
  end

  def get_ref(ref)
    @server.git_data.references.get(ref: ref)
  end

  def match_versioned_ref()
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

  def list_languages
    langs = @server.repos.languages
    LicenseAuto.logger.debug("All languaegs: #{langs}")
    langs
  end

  # @return
  # Array: [#<Hashie::Mash commit=#<Hashie::Mash sha="8065e5c64a22bd6d60e4df8d9be46b5805ec9355" url="https://api.github.com/repos/bower/bower/commits/8065e5c64a22bd6d60e4df8d9be46b5805ec9355"> name="v1.7.9" tarball_url="https://api.github.com/repos/bower/bower/tarball/v1.7.9" zipball_url="https://api.github.com/repos/bower/bower/zipball/v1.7.9">, #<Hashie::Mash commit=
  def list_tags
    @server.repos.tags.body
  end

  def list_commits
    commits = @server.repos.commits.list
  end

  def latest_commit
    latest = list_commits.first
  end

  def clone
    info = repo_info

    clone_url = info.body.fetch('clone_url')
    LicenseAuto.logger.debug(clone_url)

    trimmed_url = clone_url.gsub(/^http[s]?:\/\//, '')
    clone_dir = "#{LUTO_CACHE_DIR}/#{trimmed_url}"
    LicenseAuto.logger.debug(clone_dir)

    if Dir.exist?(clone_dir)
      git = Git.open(clone_dir, :log => LicenseAuto.logger)
      local_branch = git.branches.local[0].full
      if local_branch == @ref
        git.pull(remote='origin', branch=local_branch)
      else
        FileUtils::rm_rf(clone_dir)
        do_clone(clone_url, clone_dir)
      end
    else
      do_clone(clone_url, clone_dir)
    end
    clone_dir
  end

  def do_clone(clone_url, clone_dir)
    LicenseAuto.logger.debug(@ref)
    clone_opts = {
        :depth => 1, # Only last commit history for fast
        :branch => @ref
    }
    LicenseAuto.logger.debug(clone_url)
    Git.clone(clone_url, clone_dir, clone_opts)
  end

  def repo_info
    @server.repos.get
  end

  def filter_gitmodules
  end

  # http://www.rubydoc.info/github/piotrmurach/github/master/Github/Client/GitData/Blobs#get-instance_method
  def get_blobs(sha)
    response_wrapper = @server.git_data.blobs.get(@server.user, @server.repo, sha)
    # LicenseAuto.logger.debug(response_wrapper)
    content = response_wrapper.body.content
    encoding = response_wrapper.body.encoding
    if encoding == 'base64'
      Base64.decode64(content)
    else
      LicenseAuto.logger.error("Unknown encoding: #{encoding}")
    end
  end
end
