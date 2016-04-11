require 'httparty'
require 'license_auto/package_manager'

module LicenseAuto

  class NpmRegistry

    attr_reader :registry

    def initialize(pack_name, pack_version, registry='http://registry.npmjs.org/')
      @registry = registry
      @pack_name = pack_name
      @pack_version = pack_version
      @pack_meta = nil
    end

    # RESTful API: http://registry.npmjs.org/:pack_name
    # TEST:        http://registry.npmjs.org/grunt
    def get_package_meta
      package_meta = nil
      api_url = "#{@registry}#{@pack_name}"
      LicenseAuto.logger.debug(api_url)
      response = HTTParty.get(api_url)
      if response.code == 200
        package_meta = JSON.parse(response.body)
      else
        LicenseAuto.logger.error("Npm registry API response: #{response}")
      end
      package_meta
    end

    # RESTful API: http://registry.npmjs.org/grunt/?version=0.1.0
    def get_package_info_by_version
      api_url = "#{@registry}#{@pack_name}/?version=#{@pack_version}"
      LicenseAuto.logger.debug(api_url)
      response = HTTParty.get(api_url)
      package_info =
          case response.code
            when 200
              JSON.parse(response.licenses)
            else
              LicenseAuto.logger.error(response)
              nil
          end
    end

    # DOC: https://www.npmjs.com/package/semver
    # DOC: https://github.com/npm/node-semver
    # sem_version_range: '~1.2.3'
    def get_available_versions(sem_version_range)
      # LicenseAuto.logger.debug("sem_version_range: #{sem_version_range}")
      package_meta = get_package_meta
      all_versions = package_meta['versions']

      available_versions = all_versions.select {|version, meta|
            # Example: node -e "var semver = require('semver'); var result = semver.satisfies('1.2.3', '1.x || >=2.5.0 || 5.0.0 - 7.2.3'); console.log(result);"
            cmd = "node -e \"var semver = require('semver'); var available = semver.satisfies('#{version}', '#{sem_version_range}'); console.log(available);\""
            stdout_str, stderr_str, status = Open3.capture3(cmd)
            if stdout_str == "true\n"
              # LicenseAuto.logger.debug("available version: #{version}")
              true
            end
          }
    end

    def chose_latest_available_version(sem_version_range)
      available_versions = get_available_versions(sem_version_range)
      chosen = available_versions.keys.last
      LicenseAuto.logger.debug("chosen version: #{chosen}")
      chosen
    end
  end
end
