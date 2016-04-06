require 'hashie/mash'


module LicenseAuto

  class LicenseInfoWrapper < Hashie::Dash
    include Hashie::Extensions::Mash

    property :licenses, required: true
    property :readmes, default: []
    property :notices, default: []

  end

  class LicenseWrapper < Hashie::Dash
    include Hashie::Extensions::Mash

    property :pack_id

    property :name, default: 'UNKNOWN'
    property :sim_ratio, default: 1.0

    property :html_url
    property :download_url
    property :text

  end
end