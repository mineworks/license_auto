module LicenseAuto
  class LicenseInfo
    attr_reader :body

    def initialize(licenses)
      @body = licenses || []
    end

  end
end