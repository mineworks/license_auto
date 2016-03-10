module LicenseAuto
  class LicenseInfo < Hashie::Mash
    attr_reader :licenses

    def initialize(licenses=nil)
      @licenses = licenses || []
    end

  end
end