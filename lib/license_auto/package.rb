require 'hashie/mash'

##
# package:
# Hash {
#     language: 'Ruby',                # Ruby|Golang|Java|NodeJS|Erlang|Python|
#     name: 'bundler',
#     group: 'com.google.http-client', # Optional: Assign nil if your package is not a Java
#     version: '1.11.2',               # Optional: Assign nil if check the latest
#     project_server: 'rubygems.org'   # Optional: github.com|rubygems.org|pypi.python.org/pypi|registry.npmjs.org
# }

module LicenseAuto

  class Package < Hashie::Mash
    extend LicenseAuto

    ##
    # Default project website server of all kinds of languages
    # Key: language name
    # Value: default project server

    LANGUAGES_PROJECT_SERVER = {
        Ruby: RubyGemsOrg
    }

    def initialize(hash)
      super(hash)
      @adaptor = nil
    end

    def chose_adapter_by_language()
      begin
        @adaptor = LANGUAGES_PROJECT_SERVER.fetch(self.language.to_sym)
      rescue KeyError
        raise Exception("#{self.language} has no adapter")
        # TODO: Website::GoogleSearch
        # @adaptor = LicenseAuto::Website::Google
        # TODO: Website::GithubSearch
      end
    end

    ##
    # Entry

    def get_license_info()
      chose_adapter_by_language()

      #   # TODO: detect latest version
      #   @version = nil

      #   # TODO: fill default project_server
      #   @project_server = nil

      @adaptor.get_license_info()
    end

  end


end