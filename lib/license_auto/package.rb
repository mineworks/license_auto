require 'hashie/mash'

require 'license_auto/website/ruby_gems_org'
require 'license_auto/website/gemfury_com'
require 'license_auto/website/github_com'


module LicenseAuto

  ##
  # Package: {
  #     language: 'Ruby',                # Ruby|Golang|Java|NodeJS|Erlang|Python|
  #     name: 'bundler',
  #     group: 'com.google.http-client', # Optional: Assign nil if your package is not a Java
  #     version: '1.11.2',               # Optional: Assign nil if check the latest
  #     server: 'rubygems.org'           # Optional: github.com|rubygems.org|pypi.python.org/pypi|registry.npmjs.org
  # }

  class Package < Hashie::Mash
    extend LicenseAuto

    ##
    # Default project server of all kinds of languages.
    #
    # Key: language name
    #
    # Value: default project server

    LANGUAGES_PACKAGE_SERVER = {
        Ruby: RubyGemsOrg
    }

    ALL_SERVERS = [
        RubyGemsOrg,
        GemfuryCom,
        GithubCom,
    ]

    def initialize(hash)
      super(hash)
      @server = nil
    end

    # Class Entry
    # @return {LicenseAuto::LicenseInfoWrapper}
    # {
    #     "readmes": [
    #         {
    #             "name": "README.md",
    #             "path": "README.md",
    #             "sha": "c46767306718fbbb1320d43f6b5668a950c6b0d7",
    #             "size": 2389,
    #             "url": "https://api.github.com/repos/bundler/bundler/contents/README.md?ref=v1.11.2",
    #             "html_url": "https://github.com/bundler/bundler/blob/v1.11.2/README.md",
    #             "git_url": "https://api.github.com/repos/bundler/bundler/git/blobs/c46767306718fbbb1320d43f6b5668a950c6b0d7",
    #             "download_url": "https://raw.githubusercontent.com/bundler/bundler/v1.11.2/README.md",
    #             "type": "file",
    #             "_links": {
    #                 "self": "https://api.github.com/repos/bundler/bundler/contents/README.md?ref=v1.11.2",
    #                 "git": "https://api.github.com/repos/bundler/bundler/git/blobs/c46767306718fbbb1320d43f6b5668a950c6b0d7",
    #                 "html": "https://github.com/bundler/bundler/blob/v1.11.2/README.md"
    #             }
    #         }
    #     ],
    #     "notices": [
    #
    #     ],
    #     "licenses": [
    #         {
    #             "name": "LICENSE.md",
    #             "path": "LICENSE.md",
    #             "sha": "e356f59f949264bff1600af3476d5e37147957cc",
    #             "size": 1118,
    #             "url": "https://api.github.com/repos/bundler/bundler/contents/LICENSE.md?ref=v1.11.2",
    #             "html_url": "https://github.com/bundler/bundler/blob/v1.11.2/LICENSE.md",
    #             "git_url": "https://api.github.com/repos/bundler/bundler/git/blobs/e356f59f949264bff1600af3476d5e37147957cc",
    #             "download_url": "https://raw.githubusercontent.com/bundler/bundler/v1.11.2/LICENSE.md",
    #             "type": "file",
    #             "_links": {
    #                 "self": "https://api.github.com/repos/bundler/bundler/contents/LICENSE.md?ref=v1.11.2",
    #                 "git": "https://api.github.com/repos/bundler/bundler/git/blobs/e356f59f949264bff1600af3476d5e37147957cc",
    #                 "html": "https://github.com/bundler/bundler/blob/v1.11.2/LICENSE.md"
    #             }
    #         }
    #     ]
    # }
    def get_license_info()

      # args = {
      #     fetch_license_text: true
      # }.merge(args)

      @server.get_license_info if chose_package_server

      # TODO: uncomment these line, add Google or Yahoo!
      # if @server.nil?
      #     @server.get_license_info if chose_search_engine
      # end

    end

    private

    def chose_package_server()
      begin
        @server =
            if self.server?
              # TODO:
              LANGUAGES_PACKAGE_SERVER.fetch(self.language.to_sym).new(self)
            elsif self.language
              LANGUAGES_PACKAGE_SERVER.fetch(self.language.to_sym).new(self)
            end
      rescue KeyError => e
        LicenseAuto.logger.fatal("#{e}")
      end
    end

    def chose_search_engine()
      # TODO: Website::Google
      # logger.info("#{self.language} has no adapter. I will google it...")
      # @search_engine = LicenseAuto::SearchEngine::Google
      # TODO: Website::Github
    end

  end


end