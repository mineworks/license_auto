require 'open3'
require 'bundler'
require 'license_auto/package_manager'
require 'license_auto/website/ruby_gems_org'
# require 'license_auto/package_manager/gemfury'

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

          deps = [npm_definition.dependencies, npm_definition.dependencies].compact.map {|pack_name, semver|
            if is_valid_semver?(semver)
              certain_version = API::NpmRegistry.new(pack_name, semver).chose_one_available_version(semver)
              pack = {'name' => pack_name, 'version' => certain_version}
              pack_name_versions.push(pack)
            elsif semver =~ API::SOURCE_URL_PATTERN[:npm_urls]
              r = API::SOURCE_URL_PATTERN[:npm_urls].match(semver)
              # TODO: save by original type
              if r['host'] =~ API::SOURCE_URL_PATTERN[:github_dot_com]
                source_url = "https://github.com/#{r['owner']}/#{r['repo']}"
              else
                source_url = semver
              end
              if r['ref'] == nil
                version = 'master'
              else
                version = r['ref']
              end
              pack = {
                  'name' => pack_name,
                  'version' => version,
                  'uri' => source_url
              }
              pack_name_versions.push(pack)
            else
              pack = {
                  'name' => pack_name,
                  'version' => semver,
                  'uri' => nil
              }
              pack_name_versions.push(pack)
              # raise "Unknown semver pattern: #{semver}, pack_name"
            end
          }

            {
              dep_file: dep_file,
              deps: definition.map {|spec|
                remote =
                    case
                      when spec.source.class == ::Bundler::Source::Git
                        spec.source.uri
                      when spec.source.class == ::Bundler::Source::Rubygems
                        if spec.source.remotes.size == 1
                          spec.source.remotes.first.to_s
                        elsif spec.source.remotes.size >= 1
                          # remotes =
                          #     if Gems.info(spec.name) == RubyGemsOrg::GEM_NOT_FOUND
                          #       spec.source.remotes.reject {|uri|
                          #         uri.to_s == RubyGemsOrg::URI
                          #       }
                          #     else
                          #       spec.source.remotes
                          #     end
                          # TODO: support http://www.gemfury.com, aka multi `source` DSL; requre 'rubygems'?
                          spec.source.remotes.map {|r|
                            r.to_s
                          }.join(',')
                        end
                      when spec.source.class == ::Bundler::Source::Path::Installer
                        # Untested
                        spec.full_gem_path
                      else
                        raise('Yo, this error should ever not occur!')
                    end
                {
                    name: spec.name,
                    version: spec.version.to_s,
                    remote: remote
                }
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
      is_valid = stdout_str.gsub(/\n/, '') != 'null'
      unless is_valid
        LicenseAuto.logger.error(stdeerr)
      end
      is_valid
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

      bash_cmd = "node -e \"require('semver');\""
      LicenseAuto.logger.debug(bash_cmd)
      stdout_str, stderr_str, status = Open3.capture3(bash_cmd)
      if stderr_str
        LicenseAuto.logger.error(stderr_str)
        bash_cmd = "sudo npm install -g semver"
        LicenseAuto.logger.info("Install npm package semver globally first: #{bash_cmd}")
        return false
      else
        return true
      end
    end
  end
end