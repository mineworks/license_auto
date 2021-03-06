require 'hashie/mash'
require 'license_auto/website/github_com'
require 'license_auto/package_manager/bundler'
require 'license_auto/package_manager/npm'
require 'license_auto/package_manager/golang'
require 'license_auto/package_manager/gradle'
require 'license_auto/package_manager/maven'
require 'license_auto/package_manager/git_module'
# require 'license_auto/package_manager/bower'

module LicenseAuto
  class Repo < Hashie::Mash

    # hash example:
    #     {
    #         "clone_url": "https://github.com/mineworks/license_auto.git",
    #         "ref": "readme",
    #         "access_token": "40 chars token"
    #     }
    def initialize(hash)
      super(hash)

      if localfile == true #local repo
        @repo_dir = clone_url
        @server = []
      else
        @server = chose_repo_server
        raise("#{hash} is not a Github Repo") unless @server
        @repo_dir = nil
      end

    end

    def self.package_managers
      [
          # Bower,
          Bundler,
          Npm,
          Golang,
          Gradle,
          Maven
      ]
    end

    # @return:
    # {
    #     "LicenseAuto::Bundler": [
    #         {
    #             "dep_file": "/tmp/license_auto/cache/github.com/mineworks/license_auto.git/Gemfile.lock",
    #             "deps": [
    #                 {
    #                     "name": "addressable",
    #                     "version": "2.4.0",
    #                     "remote": "https://rubygems.org/"
    #                 },
    #                 {
    #                     "name": "anemone",
    #                     "version": "0.7.2",
    #                     "remote": "https://rubygems.org/"
    #                 },
    #                 {
    #                     "name": "ast",
    #                     "version": "2.2.0",
    #                     "remote": "https://rubygems.org/"
    #                 }
    #             ]
    #         }
    #     ],
    #     "LicenseAuto::Npm": [
    #         {
    #             "dep_file": "/tmp/license_auto/cache/github.com/mineworks/license_auto.git/package.json",
    #             "deps": [
    #                 {
    #                     "name": "bower",
    #                     "version": "v1.7.9",
    #                     "remote": "https://github.com/bower/bower.git"
    #                 },
    #                 {
    #                     "name": "lodash.isarguments",
    #                     "version": "3.0.8",
    #                     "remote": "http://registry.npmjs.org/"
    #                 },
    #                 {
    #                     "name": "lodash.isarray",
    #                     "version": "3.0.4",
    #                     "remote": "http://registry.npmjs.org/"
    #                 }
    #             ]
    #         }
    #     ]
    # }
    def find_dependencies
      if @repo_dir == nil
        @repo_dir = @server.clone
      end

      deps = {}
      Repo.package_managers.each {|pm|
        # LicenseAuto.logger.debug(pm)
        items = pm.new(@repo_dir).parse_dependencies
        unless items.empty?
          deps[pm.to_s] = items
        end
      }
      LicenseAuto.logger.debug(JSON.pretty_generate(deps))
      deps
    end


    # @return Array
    #
    def find_git_modules
      if FileTest.directory?(@repo_dir)
        pm = LicenseAuto::GitModule.new(@repo_dir)
        pm.parse_dependencies
      else
        error = "Cloned repo_dir is nil"
        LicenseAuto.logger.error(error)
        nil
      end
    end

    # def get_ref()
    #   @server.get_ref(self.ref)
    # end

    private

    def chose_repo_server
      source_code_matcher = LicenseAuto::Matcher::SourceURL.new(clone_url)
      github_matched = source_code_matcher.match_github_resource
      if github_matched
        # TODO: pass argument: ref

        @server = GithubCom.new({}, github_matched[:owner], github_matched[:repo], ref=self.ref)
      end
    end
  end
end