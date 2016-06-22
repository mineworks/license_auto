require 'httparty'
require 'hashie/mash'
require 'license_auto/package_manager'

module LicenseAuto

  class NpmRegistry < Website

    attr_reader :registry

    def initialize(package, registry='http://registry.npmjs.org/')
      super(package)
      @registry = registry
      @pack_meta = nil
    end

    # RESTful API: http://registry.npmjs.org/:pack_name
    # TEST:        http://registry.npmjs.org/grunt
    def get_package_meta
      if @package.name.include?('/')
        api_url = "#{@registry}#{@package.name.gsub('/','%2F')}"
      else
        api_url = "#{@registry}#{@package.name}"
      end
      LicenseAuto.logger.debug(api_url)
      response = HTTParty.get(api_url)

      if response.code == 200
        Hashie::Mash.new(JSON.parse(response.body))
      else
        LicenseAuto.logger.error("Npm registry API response: #{response}")
        nil
      end
    end

    # RESTful API: http://registry.npmjs.org/grunt/?version=0.1.0
    def get_package_info_by_version
      api_url = "#{@registry}#{@package.name}/?version=#{@package.version}"
      LicenseAuto.logger.debug(api_url)
      response = HTTParty.get(api_url)
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
      if package_meta == nil
        return false
      end
      all_versions = package_meta.versions


      all_versions.select {|version, meta|
        # Example: node -e "var semver = require('semver'); var result = semver.satisfies('1.2.3', '1.x || >=2.5.0 || 5.0.0 - 7.2.3'); console.log(result);"
        cmd = "node -e \"var semver = require('semver'); var available = semver.satisfies('#{version}', '#{sem_version_range}'); console.log(available);\""
        stdout_str, _stderr_str, _status = Open3.capture3(cmd)
        if stdout_str == "true\n"
          # LicenseAuto.logger.debug("available version: #{version}")
          true
        else
          # LicenseAuto.logger.debug("version: #{version}, semver: #{sem_version_range}, #{stdout_str}, #{stderr_str}")
          false
        end
      }
    end

    def chose_latest_available_version(sem_version_range)
      available_versions = get_available_versions(sem_version_range)
      if available_versions == false
        chosen = @package.version
      else
        chosen = available_versions.keys.last
      end
      LicenseAuto.logger.debug("chosen version: #{chosen} for #{@package.name}")
      chosen
    end

    def get_license_info()
      if @package.version.nil?
        begin
          @package.version = chose_latest_available_version('*')
        rescue Exception => e
          LicenseAuto.logger.error(e)
          return nil
        end
      end

      npm_info = get_package_meta
      # LicenseAuto.logger.debug(npm_info)

      raise LicenseAuto::PackageNotFound if npm_info.nil?

      license_info = LicenseAuto::LicenseInfoWrapper.new

      source_url = if npm_info.repository
                     npm_info.repository.url || npm_info.homepage_uri
                   end
      if source_url
        source_code_matcher = LicenseAuto::Matcher::SourceURL.new(source_url)
        github_matched = source_code_matcher.match_github_resource
        bitbucket_matched = source_code_matcher.match_bitbucket_resource

        if github_matched
          license_info = GithubCom.new(@package, github_matched[:owner], github_matched[:repo]).get_license_info
        elsif bitbucket_matched
          # TODO bitbucket_matched
        elsif npm_info.homepage_uri
          # LicenseAuto.logger.warn("TODO: HomepageSpider")
          # homepage_spider = HomepageSpider.new(gem_info.homepage_uri, @package.name)
          # source_code_uri = homepage_spider.get_source_code_uri
          # if source_code_uri
          #   LicenseAuto.logger.warn("call myself recursively")
          # else
          #   license_wrapper = homepage_spider.get_license_page
          #   LicenseAuto.logger.warn("omepageSpider")
          # end
        elsif not npm_info.licenses.empty?
          # TODO:
          LicenseAuto.logger.error(npm_info.licenses)
          license_files = npm_info.licenses.map {|license|
            LicenseAuto::LicenseWrapper.new(
                name: license.type,
                sim_ratio: 1.0,
                html_url: nil,
                download_url: license.url,
                text: nil
            )
          }

          license_info[:licenses] = license_files
          # LicenseAuto.logger.debug(license_info)
        elsif not npm_info.license.empty?
          # TODO: [SPDX license expression syntax version 2.0 string](https://www.npmjs.com/package/spdx)
          # Example:
          #     { "license": "ISC" }
          #     { "license": "(MIT OR Apache-2.0)" }
          # No license:
          #     { "license": "UNLICENSED"}
          # DOC: https://docs.npmjs.com/files/package.json#license
          # Eg. ["LGPL-2.1", "MIT"]
          licenses = npm_info.license.gsub(/^\(/, '').gsub(/\)$/, '').gsub(/\b(AND|OR)\b/, ' ').split(' ')
          license_files = licenses.map {|license_name|
            LicenseAuto::LicenseWrapper.new(
                name: license_name,
                sim_ratio: 1.0,
                html_url: npm_info.homepage,
                download_url: npm_info.homepage,
                text: nil
            )
          }

          license_info[:licenses] = license_files
          LicenseAuto.logger.debug(license_info)
        end

        source_url = uniform_repository_url(npm_info.repository.url)
        pack_wrapper = LicenseAuto::PackWrapper.new(
            project_url: npm_info.project_uri,
            homepage: npm_info.homepage,
            source_url: source_url
        )
        license_info[:pack] = pack_wrapper
        return license_info
      else
        raise LicenseAuto::SourceURLNotFound
      end
    end

    def uniform_repository_url(repo_url)
      git = /^git:\/\//
      git_http = /^git\+http/
      if repo_url =~ git
        repo_url.gsub(git, 'http://')
      elsif repo_url =~ git_http
        repo_url.gsub(git_http, 'http')
      else
        repo_url
      end
    end
  end
end
