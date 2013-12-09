require 'hashie/mash'
require 'license_auto/website/github_com'
require 'license_auto/package_manager/bundler'
require 'license_auto/package_manager/npm'

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
      @server = chose_repo_server
      raise("#{hash} is not a Github Repo") unless @server
    end

    def self.package_managers
      [Bundler, Npm]
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
    #                     "name": "gulp-ng-config",
    #                     "version": "1.2.1",
    #                     "remote": "http://registry.npmjs.org/"
    #                 },
    #                 {
    #                     "name": "lodash",
    #                     "version": "3.10.1",
    #                     "remote": "http://registry.npmjs.org/"
    #                 },
    #                 {
    #                     "name": "lodash._getnative",
    #                     "version": "3.9.1",
    #                     "remote": "http://registry.npmjs.org/"
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
    #                 },
    #                 {
    #                     "name": "bower",
    #                     "version": "v1.7.9",
    #                     "remote": "https://github.com/bower/bower.git"
    #                 },
    #                 {
    #                     "name": "gulp-ng-config",
    #                     "version": "1.2.1",
    #                     "remote": "http://registry.npmjs.org/"
    #                 },
    #                 {
    #                     "name": "lodash",
    #                     "version": "3.10.1",
    #                     "remote": "http://registry.npmjs.org/"
    #                 },
    #                 {
    #                     "name": "lodash._getnative",
    #                     "version": "3.9.1",
    #                     "remote": "http://registry.npmjs.org/"
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
      repo_dir = @server.clone
      deps = {}
      Repo.package_managers.each {|pm|
        # LicenseAuto.logger.debug(pm)
        items = pm.new(repo_dir).parse_dependencies
        unless items.empty?
          deps[pm.to_s] = items
        end
      }
      LicenseAuto.logger.debug(JSON.pretty_generate(deps))
      deps
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