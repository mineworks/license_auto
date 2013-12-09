require 'json'
require 'open3'
require 'httparty'

require_relative '../../conf/config'
require_relative '../api/pattern'
require_relative '../api/github'

module API
  # I have no time to research the npm cli source code(https://github.com/npm/npm-registry-client),
  # quickly write this.
  class NpmRegistry
    def initialize(pack_name, pack_version)
      @default_registry = 'http://registry.npmjs.org/'
      @pack_name = pack_name
      @pack_version = pack_version
      @pack_meta = nil
    end

    # RESTful API: http://registry.npmjs.org/:pack_name
    # TEST:        http://registry.npmjs.org/grunt
    def get_package_meta
      package_meta = nil
      api_url = "#{@default_registry}#{@pack_name}"
      $plog.debug(api_url)
      response = HTTParty.get(api_url)
      if response.code == 200
        package_meta = JSON.parse(response.body)
      elsif response.code == 404
        $plog.error("!!! Npm registry API 404 Not found: #{response}")
      else
        $plog.error("!!! Npm registry API error response: #{response}")
      end
      package_meta
    end

    # RESTful API: http://registry.npmjs.org/grunt/?version=0.1.0
    def get_package_info_by_version
      package_info = nil
      api_url = "#{@default_registry}#{@pack_name}/?version=#{@pack_version}"
      $plog.debug(api_url)
      response = HTTParty.get(api_url)
      if response.code == 200
        package_info = JSON.parse(response.body)
      elsif response.code == 404
        $plog.error("!!! Npm registry API 404 Not found: #{response}")
      else
        $plog.error("!!! Npm registry API error response: #{response}")
      end
      package_info
    end

    # DOC: https://www.npmjs.com/package/semver
    # DOC: https://github.com/npm/node-semver
    # sem_version_range: '~1.2.3'
    def get_available_versions(sem_version_range)
      available_versions = []
      package_meta = get_package_meta
      all_versions = package_meta['versions']

      all_versions.each_key {|version|
        # node -e "var semver = require('semver'); var result = semver.satisfies('1.2.3', '1.x || >=2.5.0 || 5.0.0 - 7.2.3'); console.log(result);"
        cmd = "node -e \"var semver = require('semver'); var available = semver.satisfies('#{version}', '#{sem_version_range}'); console.log(available);\""
        # $plog.debug(cmd)
        Open3.popen3(cmd) {|i,o,e,t|
          out = o.readlines
          error = e.readlines
          if error.length > 0
            $plog.error(error)
            raise "node -e evaluate script error: #{cmd}, #{error}"
          elsif out.length > 0
            available = out[0].gsub(/\n/,'')
            if available == 'true'
              $plog.debug("available version: #{version}")
              available_versions.push(version)
            end
          else
            raise "node -e evaluate script error: #{cmd}, #{error}"
          end
        }
      }
      available_versions
    end

    def chose_one_available_version(sem_version_range)
      available_versions = get_available_versions(sem_version_range)
      # TODO: is it right?
      $plog.debug("chose version: #{available_versions.last}")
      available_versions.last
    end

    def get_license_info()
      license = nil
      license_url = nil
      license_text = nil
      source_url = nil
      homepage = nil

      pack_info = get_package_info_by_version
      $plog.debug("Npm registry pack_info: #{pack_info}")
      if pack_info
        licenses = pack_info['licenses']
        if licenses != nil
          # TODO: multi licenses:
          # eg. http://registry.npmjs.org/grunt/?version=0.1.0
          license = licenses[0]['type']

          # TODO: convert http://github.com/cowboy/grunt/blob/master/LICENSE-MIT to raw
          license_url = licenses[0]['url']
          if license_url =~ API::SOURCE_URL_PATTERN[:github_html_page]
            license_url, license_text = API::Github.convert_htmlpage_to_raw_url(license_url)
          end
        else
          license = pack_info['license']
        end

        homepage = pack_info['homepage']
        repository = pack_info['repository']
        if repository['type'] == 'git'
          source_url = repository['url'].gsub(/(git:\/\/|git\+ssh:\/\/git\@)/, 'http://').gsub(/\.git$/, '')
        elsif repository['type'] =~ 'http'
          source_url = repository['url']
        else
          $plog.info("repository special type: #{repository}")
        end

        if license_text == nil
          # TODO:
        end
      end
      {
        license: license,
        license_url: license_url,
        license_text: license_text,
        source_url: source_url,
        homepage: homepage
      }
    end
  end
end

if __FILE__ == $0
  # name = 'browserify'
  # version = '12.0.1'
  name = 'grunt'
  version = '0.1.0'
  n = API::NpmRegistry.new(name, version)
  pack_info = n.get_package_info_by_version

  license_info = n.get_license_info
  $plog.info(license_info)

  # pack_meta = n.get_package_meta
  # p pack_meta
  # p pack_meta['versions']

  # sem_ver = '>=2.5.0'
  # vs = n.get_available_versions(sem_ver)
  # p vs
end