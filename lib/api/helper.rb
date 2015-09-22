module API

  class Helper
    def self.is_license_file(filename)
      return filename =~ API::FILE_NAME_PATTERN[:license_file]
    end

    def self.is_readme_file(filename)
      return filename =~ API::FILE_NAME_PATTERN[:readme_file]
    end
  end

end
