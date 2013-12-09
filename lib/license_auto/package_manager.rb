require 'open-uri'

module LicenseAuto
  class PackageManager

    attr_reader :raw_contents
    # Dependency file pattern, Array, SHOULD to be override
    DEPENDENCY_PATTERN = nil

    # def self.inherited(child_class)
    #   methods = child_class.instance_methods(false)
    #   puts methods
    #   ['initialize', :parse_dependencies].each do |x|
    #     raise "The class #{child_class} should have a interface: #{x}" unless methods.include?(x)
    #   end
    # end

    # uri: <./filepath/name.txt|/some/absolute/file/path/name|http://somesite.com/foo/bar/baz.file>
    #
    def initialize(uri)
      @raw_contents =
          open(uri) do |f|
            f.read
          end
      @dependencies = parse_dependencies
    end

    def parse_dependencies
      []
    end
  end
end