require 'license_auto/logger'

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

  class VirtualMethodError < RuntimeError
    ##
    # Just call to super with some fancy message.
    def initialize(name)
      message = "Error: Pure virtual method '#{name}' called"
      super(message)
      logger.error(message)
    end
  end
end
