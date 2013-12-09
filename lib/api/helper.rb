require_relative './pattern'
module API

  class Helper
    def self.is_license_file(filename)
      return filename =~ API::FILE_NAME_PATTERN[:license_file]
    end

    # file_pathname = 'foo/to/bar'
    def self.is_root_file(file_pathname)
      return file_pathname.split('/').size == 2
    end

    def self.is_readme_file(filename)
      return filename =~ API::FILE_NAME_PATTERN[:readme_file]
    end

    def self.is_notice_file(filename)
      return filename =~ API::FILE_NAME_PATTERN[:notice_file]
    end
  end

end
