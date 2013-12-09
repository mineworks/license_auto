require 'hashie/mash'

module LicenseAuto

  ##
  # Package: {
  #     language: 'Ruby',                # Ruby|Golang|Java|NodeJS|Erlang|Python|
  #     name: 'bundler',
  #     group: 'com.google.http-client', # Optional: Assign nil if your package is not a Java
  #     version: '1.11.2',               # Optional: Assign nil if check the latest
  #     project_server: 'rubygems.org'   # Optional: github.com|rubygems.org|pypi.python.org/pypi|registry.npmjs.org
  # }

  class Package < Hashie::Mash
    extend LicenseAuto

    ##
    # Default project website server of all kinds of languages.
    #
    # Key: language name
    #
    # Value: default project server

    LANGUAGES_PROJECT_SERVER = {
        Ruby: RubyGemsOrg
    }

    def initialize(hash)
      super(hash)
      @server = nil
    end

    ##
    # Class Entry

    def get_license_info()
      # TODO: uncomment this line
      # chose_project_server() unless chose_project_server()

      @server.get_license_info() if chose_project_server()


      #   # TODO: detect latest version
      #   @version = nil

      #   # TODO: fill default project_server
      #   @project_server = nil

    end

    private

    def chose_project_server()
      begin
        @server = LANGUAGES_PROJECT_SERVER.fetch(self.language.to_sym).new(self)
      rescue KeyError => e
        return nil
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