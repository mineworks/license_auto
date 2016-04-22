# [Maven3](https://maven.apache.org/index.html)
# [Introduction to the Dependency Mechanism](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html)

require 'bundler'
require 'license_auto/package_manager'

module LicenseAuto
  class Maven < LicenseAuto::PackageManager

    LANGUAGE = 'Java'

    # DOC: https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Scope
    scopes = ""
    DEPENDENCY_PATTERN = /^\[INFO\]\s+(?<group>.+):(?<name>.+):(?<type>.+):(?<version>.+):(?<scope>(compile|provided|runtime|test|system|import))$/

    def initialize(path)
      super(path)
    end

    def dependency_file_pattern
      /#{@path}\/pom\.xml$/i
    end

    def parse_dependencies
      build_files = dependency_file_path_names
      if build_files.empty?
        LicenseAuto.logger.info("#{LANGUAGE}: #{dependency_file_pattern} file not exist")
        []
      else
        build_files.map {|dep_file|
          LicenseAuto.logger.debug(dep_file)

          {
              dep_file: dep_file,
              deps: collect_dependencies
          }
        }
      end
      # LicenseAuto.logger.debug(JSON.pretty_generate(deps))
    end

    # @return example
    # => Array: [{:name=>"junit:junit", :version=>"4.8", :remote=>nil}]
    def collect_dependencies
      deps =
          if resolve_dependencies
            list_dependencies.map {|dep|
              group, name, type, version, scope = dep.split(':')
              {
                  name: [group, name].join(':'),
                  version: version,
                  remote: nil
              }
            }
          else
            []
          end
      LicenseAuto.logger.debug(deps)
      deps
    end

    def resolve_dependencies
      bool = false
      Dir.chdir(@path) do
        cmd = 'mvn dependency:resolve'
        stdout_str, stderr_str, _status = Open3.capture3(cmd)
        if stdout_str.length > 0
          # LicenseAuto.logger.debug("stdout_str: #{stdout_str}")
          if stdout_str.include?("[INFO] BUILD SUCCESS")
            bool = true
          end
        end
      end
      bool
    end

    # Command output sample:
    # [INFO]
    # [INFO] ------------------------------------------------------------------------
    # [INFO] Building GitHub Maven Plugin Example 0.1-SNAPSHOT
    # [INFO] ------------------------------------------------------------------------
    # [INFO]
    # [INFO] --- maven-dependency-plugin:2.8:list (default-cli) @ github-maven-example ---
    # [INFO]
    # [INFO] The following files have been resolved:
    # [INFO]    junit:junit:jar:4.8:test
    # [INFO]
    # [INFO] ------------------------------------------------------------------------
    # [INFO] BUILD SUCCESS
    # [INFO] ------------------------------------------------------------------------
    # [INFO] Total time: 1.819 s
    # [INFO] Finished at: 2016-04-18T15:26:58+08:00
    # [INFO] Final Memory: 14M/155M
    # [INFO] ------------------------------------------------------------------------
    #
    # @return sample:
    #     Set.new(["junit:junit:jar:4.8:test"])
    def list_dependencies
      if resolve_dependencies
        deps = Set.new
        Dir.chdir(@path) do
          cmd = 'mvn dependency:list'
          out, err, _st = Open3.capture3(cmd)
          # LicenseAuto.logger.debug("#{out}")
          if out.include?("The following files have been resolved:")
            out.split("\n").each {|line|
              matched = DEPENDENCY_PATTERN.match(line)
              # LicenseAuto.logger.debug("#{line}, matched: #{matched}")
              if matched
                group_name_version = line.gsub!(/\[INFO\]/,'').strip!
                deps.add(group_name_version)
              end
            }
          else
            LicenseAuto.logger.error("#{err}")
          end
        end
        deps
      end
    end

    def self.check_cli
      cmd = 'mvn -v'
      stdout_str, stderr_str, _status = Open3.capture3(cmd)
      if stdout_str.include?('Apache Maven 3')
        true
      else
        LicenseAuto.logger.error("stdout_str: #{stdout_str}, stderr_str: #{stderr_str}")
        false
      end
    end
  end
end