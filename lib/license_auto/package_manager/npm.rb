require 'open3'
require 'bundler'
require 'license_auto/package_manager'
require 'license_auto/website/npm_registry'

module LicenseAuto
  class Npm < LicenseAuto::PackageManager

    LANGUAGE = 'NodeJS'

    def initialize(path)
      super(path)
    end

    def dependency_file_pattern
      /#{@path}\/(src\/|source\/)?package\.json$/
    end

    def parse_dependencies

      package_json_files = dependency_file_path_names
      if package_json_files.empty?
        LicenseAuto.logger.info("#{dependency_file_pattern} file not exisit")
        return []
      else
        package_json_files.map {|dep_file|
          LicenseAuto.logger.debug(dep_file)
          npm_definition = Hashie::Mash.new(JSON.parse(File.read(dep_file)))

          {
            dep_file: dep_file,
            deps: [npm_definition.dependencies, npm_definition.dependencies].compact.map {|hash|
                hash.map {|pack_name, semver|
                  if LicenseAuto::Npm.is_valid_semver?(semver)
                    npm_registry = LicenseAuto::NpmRegistry.new(pack_name, semver)
                    available_version = npm_registry.chose_latest_available_version(semver)
                    {
                        name: pack_name,
                        version: available_version,
                        remote: npm_registry.registry
                    }
                  end
                }

              # elsif semver =~ API::SOURCE_URL_PATTERN[:npm_urls]
              #   r = API::SOURCE_URL_PATTERN[:npm_urls].match(semver)
              #   # TODO: save by original type
              #   if r['host'] =~ API::SOURCE_URL_PATTERN[:github_dot_com]
              #     source_url = "https://github.com/#{r['owner']}/#{r['repo']}"
              #   else
              #     source_url = semver
              #   end
              #   if r['ref'] == nil
              #     version = 'master'
              #   else
              #     version = r['ref']
              #   end
              #   pack = {
              #       'name' => pack_name,
              #       'version' => version,
              #       'uri' => source_url
              #   }
              #   pack_name_versions.push(pack)
              # else
              #   pack = {
              #       'name' => pack_name,
              #       'version' => semver,
              #       'uri' => nil
              #   }
              #   pack_name_versions.push(pack)
                # raise "Unknown semver pattern: #{semver}, pack_name"
              # end
            }
          }
        }
      end
      # LicenseAuto.logger.debug(JSON.pretty_generate(dep_files))
    end

    # semver: {String}
    def self.is_valid_semver?(semver)
      node_cmd = "node -e \"var semver = require('semver'); var valid = semver.validRange('#{semver}'); console.log(valid)\""
      LicenseAuto.logger.debug(node_cmd)
      stdout_str, stderr_str, status = Open3.capture3(node_cmd)
      is_invalid = stdout_str.gsub(/\n/, '') == 'null'
      if is_invalid
        LicenseAuto.logger.error("semver: #{semver} is not a valid sem-version")
      else
        LicenseAuto.logger.debug("semver: #{semver} is valid")
      end
      not is_invalid
    end

    # TODO: move
    def self.check_cli
      # TODO check node
      bash_cmd = "node -v"
      LicenseAuto.logger.debug(bash_cmd)
      stdout_str, stderr_str, status = Open3.capture3(bash_cmd)
      node_version = /v5\.\d+\.\d+/
      if not stderr_str.empty?
        LicenseAuto.logger.error(stderr_str)
        return false
      elsif not stdout_str =~ node_version
        error = "NodeJS version: #{stdout_str} not satisfied: #{node_version}"
        LicenseAuto.logger.error(error)
        return false
      end

      bash_cmd = "node -e \"const semver = require('semver');\" -r semver"
      LicenseAuto.logger.debug(bash_cmd)
      stdout_str, stderr_str, status = Open3.capture3(bash_cmd)
      unless stderr_str.empty?
        LicenseAuto.logger.error(stderr_str)
        # bash_cmd = "sudo npm install -g semver"
        LicenseAuto.logger.info(
            "\n1. Install npm package semver globally first:\n
              #{bash_cmd}\n
             2. export NODE_PATH=/usr/local/lib/node_modules/\n")
        return false
      end

      return true
    end
  end
end