# http://bower.herokuapp.com/packages
#
# Find package:
#     curl http://bower.herokuapp.com/packages/jquery
#
# [Registry route]https://github.com/bower/registry/blob/master/lib/routes/index.js

require 'httparty'
require 'license_auto/matcher'
require 'license_auto/package_manager'

module LicenseAuto
  class BowerHerokuappCom < Website

    REGISTRY = 'http://bower.herokuapp.com/packages'

    def initialize(package, registry=REGISTRY)
      super(package)
      @registry = registry
      @pack_meta = nil
    end

    def get_license_info
      url = get_url

      source_code_matcher = LicenseAuto::Matcher::SourceURL.new(url)
      github_matched = source_code_matcher.match_github_resource

      if github_matched
        GithubCom.new(@package, github_matched[:owner], github_matched[:repo]).get_license_info
      else
        raise LicenseAuto::SourceURLNotFound
      end

      # LicenseAuto::LicenseInfoWrapper.new(
      #
      # )
    end

    # GET http://bower.herokuapp.com/packages/jquery
    def get_url
      uri = "#{REGISTRY}/#{@package.name}"
      response = HTTParty.get(uri)
      if response.code == 200
        JSON.parse(response.body)['url']
      end
    end

  end
end
