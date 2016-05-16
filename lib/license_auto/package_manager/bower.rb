# https://github.com/bower/registry


require 'open3'
require 'set'
require 'license_auto/package_manager'
require 'license_auto/website/bower_herokuapp_com'

module LicenseAuto
  class Bower < LicenseAuto::PackageManager

    LANGUAGE = 'Bower'

    def initialize(path)
      super(path)
    end

    # Fake
    def dependency_file_pattern
      /#{@path}\/bower\.json$/
    end

    def parse_dependencies
      bower_files = dependency_file_path_names
      if bower_files.empty?
        LicenseAuto.logger.info("#{LANGUAGE}: #{dependency_file_pattern} file not exist")
        []
      else
        dep_file = bower_files.first
        LicenseAuto.logger.debug(dep_file)
        [
            {
                dep_file: dep_file,
                deps: collect_dependencies(dep_file)
            }
        ]
      end
      # LicenseAuto.logger.debug(JSON.pretty_generate(deps))
    end

    # semver: {String}
    def self.is_valid_semver?(semver)
      node_cmd = "node -e \"var semver = require('semver'); var valid = semver.validRange('#{semver}'); console.log(valid)\""
      # LicenseAuto.logger.debug(node_cmd)
      stdout_str, _stderr_str, _status = Open3.capture3(node_cmd)
      is_invalid = stdout_str.gsub(/\n/, '') == 'null'
      # if is_invalid
      #   LicenseAuto.logger.error("semver: #{semver} is not a valid sem-version")
      # else
      #   LicenseAuto.logger.debug("semver: #{semver} is valid")
      # end
      not is_invalid
    end

    def collect_dependencies(dep_file)
      spec = Hashie::Mash.new(JSON.parse(File.read(dep_file)))

      specs = if spec.devDependencies
                spec.dependencies.merge(spec.devDependencies)
              else
                spec.dependencies
              end
      LicenseAuto.logger.debug(specs.to_json)
      specs.map {|name, semver|
        {
            name: name,
            version: semver.gsub(/~/, ''),
            remote: LicenseAuto::BowerHerokuappCom::REGISTRY
        }
      }
    end

    def self.check_cli
      bash_cmd = "bower -version"
      # LicenseAuto.logger.debug(bash_cmd)
      stdout_str, stderr_str, _status = Open3.capture3(bash_cmd)
      bower_version = /1\./

      if not stderr_str.empty?
        LicenseAuto.logger.error(stderr_str)
        return false
      elsif not stdout_str =~ bower_version
        error = "Golang version: #{stdout_str} not satisfied: #{bower_version}"
        LicenseAuto.logger.error(error)
        return false
      end

      return true
    end
  end
end