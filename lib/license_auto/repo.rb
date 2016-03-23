require 'hashie/mash'
require 'license_auto/website/github_com'

module LicenseAuto
  class Repo < Hashie::Mash

    def initialize(hash)
      super(hash)
      @server = chose_repo_server
      raise("#{hash} is not a Github Repo") unless @server
    end

    def find_dependencies
      langs = @server.list_languages
      if langs.has_key?(:Go)
        # TODO:
        repo_dir = @server.clone
      end
    end

    def find_gems

    end

    private

    def chose_repo_server
      source_code_matcher = LicenseAuto::Matcher::SourceURL.new(gem_info.source_code_uri)
      github_matched = source_code_matcher.match_github_resource
      if github_matched
        # TODO: pass argument: ref
        @server = GithubCom.new(@package, github_matched[:owner], github_matched[:repo])
      end
    end
  end
end