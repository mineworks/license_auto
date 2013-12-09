require 'hashie/mash'
require 'license_auto/website/github_com'

module LicenseAuto
  class Repo < Hashie::Mash

    def initialize(hash)
      super(hash)
      @server = nil
    end

    def find_dependencies
      deps = {}
      gems = find_gems
      return
    end

    def find_gems

    end



  end
end