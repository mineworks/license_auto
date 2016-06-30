# https://git-scm.com/book/en/v2/Git-Tools-Submodules

require 'open3'
require 'license_auto/package_manager'

module LicenseAuto
  class GitModule < LicenseAuto::PackageManager

    LANGUAGE = 'GitModule'

    def initialize(path)
      super(path)
    end

    def dependency_file_pattern
      %r{#{@path}/\.gitmodules$}
    end

    def parse_dependencies
      git_module_files = dependency_file_path_names
      if git_module_files.empty?
        LicenseAuto.logger.info("#{LANGUAGE}: #{dependency_file_pattern} file not exist")
        []
      elsif git_module_files.size == 1
        dep_file = git_module_files.first
        LicenseAuto.logger.debug(dep_file)
        modules = parse_modules(dep_file)
        LicenseAuto.logger.debug(modules)
        [
            {
                dep_file: dep_file,
                deps: modules
            }
        ]
      end
      # LicenseAuto.logger.debug(JSON.pretty_generate(dep_files))
    end

    def self.check_cli
      cmd = 'git version'
      stdout_str, stderr_str, _status = Open3.capture3(cmd)
      if stdout_str.include?('git version')
        true
      else
        LicenseAuto.logger.error("stdout_str: #{stdout_str}, stderr_str: #{stderr_str}")
        false
      end
    end

    private

    # Run `git submodule status` in the path of the dep_file.
    # The output takes the format [+- ]?version path (refs/branch)
    def parse_versions
      cmd = 'git submodule status'
      versions = {}
      LicenseAuto.logger.debug(@path)
      Dir.chdir(@path) do
        stdout_str, stderr_str, _status = Open3.capture3(cmd)
        if !stdout_str.empty?
          LicenseAuto.logger.debug(stdout_str)
          stdout_str.split("\n").each {|line|
            if line =~ %r{^[-\+\s]([0-9a-fA-F]{40})\s+([\w\s\/\.]+)\s?\(?}i
              versions[Regexp.last_match[2].strip] = Regexp.last_match[1]
            end
          }
        else
          LicenseAuto.logger.error(stderr_str)
        end
      end
      LicenseAuto.logger.debug("versions: #{versions}")
      versions
    end

    def parse_modules(dep_file)
      versions = parse_versions

      # Build an array of submodules from .gitmodules that contains
      # a hash of the name=value pairs for the submodule
      submodules = []
      submodule_hash = nil
      lines = File.readlines(dep_file)
      lines.each{|line|
        if line =~ /^\[submodule \"(.+)\"\]/i
          submodule_hash = {}
          submodule_hash[:name] = Regexp.last_match[1]
          submodules.push(submodule_hash)
        elsif submodule_hash && line =~ /=/
          name, value = line.split('=').map(&:strip)
          submodule_hash[name.to_sym] = value
        end
      }
      merge_submodule_versions(submodules, versions)
    end

    # Merge verisons and submodules.  Remove any submodules that
    # don't have a version.  They're likely things that were deleted
    # with an older version of git that didn't clean up .gitmodules.
    def merge_submodule_versions(submodules, versions)
      submodules.each{|submodule|
        path = submodule[:path]
        version = versions[path]
        if version
          submodule[:version] = version
          submodule[:remote] = submodule[:url].gsub(/\.git$/, '')
        else
          LicenseAuto.logger.debug("removing (missing from versions): #{submodule}")
          submodules.delete(submodule)
        end
      }
      LicenseAuto.logger.debug("deps: #{submodules}")
      submodules
    end
  end
end
