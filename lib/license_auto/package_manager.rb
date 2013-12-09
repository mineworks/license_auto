require 'open-uri'
require 'find'
require 'license_auto/logger'
require 'license_auto/module'

module LicenseAuto
  class PackageManager

    virtual :initialize,
            :parse_dependencies,
            :dependency_file_pattern,
            :check_cli

    # def self.package_managers
    #   [Bundler, NPM, Pip, Bower, Maven, Gradle, CocoaPods, Rebar, Nuget]
    # end

    # @uri:
    #   ./filepath/name.txt
    #   /some/absolute/file/path/name
    #   http://somesite.com/foo/bar/baz.file
    def initialize(path)
      @path = path
    end

    # @return Array[Dependency]
    def parse_dependencies; end

    # @return Array[Regexp]
    def dependency_file_pattern; end

    # return Boolean
    def check_cli; end

    def dependency_file_path_names(pattern=dependency_file_pattern)
      if FileTest.directory?(@path)
        Find.find(@path).select do |filename|
          FileTest.file?(filename) && filename =~ pattern
        end
      else
        LicenseAuto.logger.fatal("The repo path: #{@path} does not exist!")
      end
    end
  end
end