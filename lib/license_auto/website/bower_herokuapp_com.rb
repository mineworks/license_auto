# http://bower.herokuapp.com/packages
#
# Find package:
#     curl http://bower.herokuapp.com/packages/jquery
#
# [Registry route]https://github.com/bower/registry/blob/master/lib/routes/index.js

require 'httparty'
require 'license_auto/matcher'

module LicenseAuto
  class BowerHerokuappCom

    REGISTRY = 'http://bower.herokuapp.com/packages'

    def initialize(name, version)
      @name = name
      @version = version
    end

    def get_license_info

      LicenseAuto::LicenseInfoWrapper.new(

      )
    end

    # GET http://bower.herokuapp.com/packages/jquery
    def get_url
      uri = "#{REGISTRY}/#{@name}"
      response = HTTParty.get(uri)
      if response.code == 200
        JSON.parse(response.body)['url']
      end
    end

  end
end
