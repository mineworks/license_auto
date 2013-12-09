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
        LicenseAuto.logger.info("#{LANGUAGE}: #{dependency_file_pattern} file not exist")
        return []
      else
        package_json_files.map {|dep_file|
          LicenseAuto.logger.debug(dep_file)
          npm_definition = Hashie::Mash.new(JSON.parse(File.read(dep_file)))

          {
            dep_file: dep_file,
            deps: [npm_definition.dependencies, npm_definition.devDependencies].compact.map {|hash|
                hash.map {|pack_name, semver|
                  available_version, remote =
                      if semver =~ /^file:/
                        # DOC: https://docs.npmjs.com/files/package.json#local-paths
                        ['local-path', semver]
                      elsif LicenseAuto::Npm.is_valid_semver?(semver)
                        pack = Hashie::Mash.new(
                            "language": "NodeJS",
                            "name": pack_name,
                            "group": "",
                            "version": semver,
                            "server": "registry.npmjs.org"
                        )
                        npm_registry = LicenseAuto::NpmRegistry.new(pack)
                        version = npm_registry.chose_latest_available_version(semver)
                        [version, npm_registry.registry]
                      else
                        # DOC: https://docs.npmjs.com/files/package.json#git-urls-as-dependencies
                        git_url = semver.gsub(/^git\+/, '')
                        matcher = LicenseAuto::Matcher::SourceURL.new(git_url)
                        github_matched = matcher.match_github_resource
                        if github_matched
                          # TODO: ref=github_matched[:ref]
                          github = GithubCom.new({}, github_matched[:owner], github_matched[:repo])
                          version = github.list_tags.first.name
                          LicenseAuto.logger.debug(version)
                          [version, git_url]
                        end
                      end
                  {
                      name: pack_name,
                      version: available_version,
                      remote: remote
                  }
                }
            }.flatten
          }
        }
      end
      # LicenseAuto.logger.debug(JSON.pretty_generate(dep_files))
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

    # TODO: move
    def self.check_cli
      bash_cmd = "node -v"
      LicenseAuto.logger.debug(bash_cmd)
      stdout_str, stderr_str, status = Open3.capture3(bash_cmd)
      node_version = /v[456]\.\d+\.\d+/
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
        LicenseAuto.logger.info(
            "\nInstall npm packages first using:\n
              $ npm install\n")
        return false
      end

      return true
    end
  end
end