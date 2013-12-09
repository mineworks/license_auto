require 'bundler'
require 'license_auto/package_manager'
# require 'license_auto/website/'

module LicenseAuto
  class Gradle < LicenseAuto::PackageManager

    LANGUAGE = 'Java'

    DEPENDENCY_PATTERN = /\\---\s(?<group>.+):(?<name>.+):(?<version>.+)/

    def initialize(path)
      super(path)
    end

    def dependency_file_pattern
      /#{@path}\/build.gradle$/i
    end

    def parse_dependencies
      build_files = dependency_file_path_names
      if build_files.empty?
        LicenseAuto.logger.info("#{dependency_file_pattern} file not exisit")
        []
        # TODO: check his sub dir has `build.gradle` or not
      else
        build_files.map {|dep_file|
          LicenseAuto.logger.debug(dep_file)

          {
              dep_file: dep_file,
              deps: collect_dependencies.map {|dep|
                group, name, version = dep.split(':')
                {
                    name: [group, name].join(':'),
                    version: version,
                    remote: nil
                }
              }
          }
        }
      end
      # LicenseAuto.logger.debug(JSON.pretty_generate(dep_files))
    end

    def self.check_cli
      cmd = 'gradle --version'
      stdout_str, stderr_str, _status = Open3.capture3(cmd)
      if stdout_str.include?('Gradle 2.8')
        true
      else
        LicenseAuto.logger.error("stdout_str: #{stdout_str}, stderr_str: #{stderr_str}")
        false
      end
    end

    # Out put sample:
    # ------------------------------------------------------------
    # Root project
    # ------------------------------------------------------------
    #
    # Root project 'maven-gradle-comparison-dependency-simplest'
    # No sub-projects
    def list_projects
      cmd = "gradle -q project"
      LicenseAuto.logger.debug(@path)
      projects = []
      Dir.chdir(@path) do
        stdout_str, stderr_str, _status = Open3.capture3(cmd)
        if stdout_str
          LicenseAuto.logger.debug(stdout_str)
          stdout_str.split("\n").each {|line|
            sub_project_pattern = /Project\s\'(:)?(?<project_name>.+)\'/
            matched = sub_project_pattern.match(line)
            if matched
              projects.push(match_result[:project_name])
            end
          }
        else
          LicenseAuto.logger.error(stderr_str)
        end
        projects
      end
    end

    def collect_dependencies
      root_deps = list_dependencies
      projects = list_projects
      projects.each {|project_name|
        deps = list_dependencies(project_name)
        root_deps.merge(deps)
      }
      root_deps
    end

    # @return sample:
    #     Set.new(["commons-beanutils:commons-beanutils:1.8.3", "commons-logging:commons-logging:1.1.1", "junit:junit:4.8.2"])
    def list_dependencies(project_name=nil)
      Dir.chdir(@path) do
        deps = Set.new
        cmd = if project_name
                "gradle -q #{project_name}:dependencies"
              else
                "gradle -q dependencies"
              end
        LicenseAuto.logger.debug("cmd: #{cmd}")

        stdout_str, stderr_str, _status = Open3.capture3(cmd)
        if stdout_str.length > 0
          LicenseAuto.logger.debug("stdout_str: #{stdout_str}")
          stdout_str.split("\n").each {|line|
            matched = DEPENDENCY_PATTERN.match(line)
            # LicenseAuto.logger.debug("#{line}, matched: #{matched}")
            if matched
              group_name_version = matched.to_s.gsub(/\\---\s/, '')
              # External dependencies
              # DOC: https://docs.gradle.org/current/userguide/artifact_dependencies_tutorial.html#N105E1
              deps.add(group_name_version)
            end
          }
        else
          LicenseAuto.logger.error("stderr_str: #{stderr_str}")
        end
        LicenseAuto.logger.debug(deps)
        deps
      end
    end
  end
end