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

    ##
    # Class Entry

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
        raise(e)
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