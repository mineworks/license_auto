module LicenseAuto
  class LicenseAutoError < StandardError
    def initialize(message="LicenseAuto Error Occurred")
      super
    end

    def message
    end
  end

  class PackageNotFound < LicenseAutoError
    def initialize(message=nil, server=nil)
      @message = message
      @server = server
    end
    def message
      "Package #{@message} can not be found in remote server #{@server}"
    end
  end
end
