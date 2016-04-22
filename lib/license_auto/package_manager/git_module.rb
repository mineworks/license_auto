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
      /#{@path}\/\.gitmodules$/
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

    def parse_modules(dep_file)
      lines = File.readlines(dep_file)
      module_pattern = /url\s=\s(?<url>.+)(\.git)?$/
      lines.map {|line|
        matched = module_pattern.match(line)
        if matched
          LicenseAuto.logger.debug("matched: #{matched}, .gitmodule spec: #{line}")
          clone_url = matched[:url].gsub(/\.git$/, '')
          {
              name: clone_url,
              # TODO: fetch version infomation from .git/ dir is to complex
              version: nil,
              remote: clone_url
          }
        end
      }.compact
    end



  end
end