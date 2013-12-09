require 'hashie/mash'
require 'license_auto/website/github_com'
require 'license_auto/package_manager/bundler'

module LicenseAuto
  class Repo < Hashie::Mash

    def initialize(hash)
      super(hash)
      @server = chose_repo_server
      raise("#{hash} is not a Github Repo") unless @server
    end

    def self.package_managers
      [Bundler]
    end

    def find_dependencies
      repo_dir = @server.clone
      deps = {}
      Repo.package_managers.each {|pm|
        deps[pm.to_s.to_sym] = pm.new(repo_dir).parse_dependencies
      }
      deps
    end

    private

    def chose_repo_server
      source_code_matcher = LicenseAuto::Matcher::SourceURL.new(clone_url)
      github_matched = source_code_matcher.match_github_resource
      if github_matched
        # TODO: pass argument: ref
        @server = GithubCom.new(@package, github_matched[:owner], github_matched[:repo], ref=ref)
      end
    end
  end
end