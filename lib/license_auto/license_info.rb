module LicenseAuto
  class LicenseInfo < Hashie::Mash
    attr_reader :licenses

    def initialize(**args)
      @licenses = args[:licenses]
    end

  end
end