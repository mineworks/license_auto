require_relative '../lib/cloner'

# TODO: remove this module
module LicenseAuto
  include Cloner
end

module License

  # TODO: module Auto?
  class Auto

    def initialize()

    end

    ##
    # Return LicenseInfo
    # package = {
    #     language: 'Ruby',                # Ruby|Golang|Java|NodeJS|Erlang|Python|
    #     name: 'bundler',
    #     group: 'com.google.http-client',  # Optional: Assign nil if your package is not a Java
    #     version: '1.11.2',               # Optional: Assign nil if check the latest
    #     project_server: 'rubygems.org'   # Optional: github.com|rubygems.org|pypi.python.org/pypi|registry.npmjs.org
    # }
    def get_license_info(pack)
      return pack
    end
  end
end