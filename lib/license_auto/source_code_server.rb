module LicenseAuto
  class SourceCodeServer
    def initialize(source_code_uri)
      @source_code_uri = source_code_uri
      @website = match_website(source_code_uri)
    end

    # @Return a subclass of LicenseAuto::Website
    def match_website(source_code_uri)

    end
  end
end