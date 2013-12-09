require 'hashie/mash'


module LicenseAuto

  class LicenseInfoWrapper < Hashie::Dash
    include Hashie::Extensions::Mash

    property :licenses, default: []
    property :readmes, default: []
    property :notices, default: []

    property :homepage, default: nil
    property :project_url, default: nil
    property :source_url, default: nil
    property :cmt, default: nil

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