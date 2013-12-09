require 'bundler'
require 'license_auto/package_manager'

module LicenseAuto
  class Bundler < LicenseAuto::VirtualPackageManager
    def initialize(path)
      super(path)
    end

    def dependency_file_pattern
      /gem.*\.lock/i
    end

    def parse_dependencies
      dependency_file_path_names.each {|dep_file|
        ::Bundler::LockfileParser.new(::Bundler.read_file(dep_file))
      }
    end
  end
end