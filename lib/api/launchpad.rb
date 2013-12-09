require 'httparty'
module API
  class Launchpad
    # DOC: https://launchpad.net/+apidoc/1.0.html
    def initialize(distribution, distro_series, binary_package_name, binary_package_version, architecture='amd64')
      @distribution = distribution
      @distro_series = distro_series
      @binary_package_name = binary_package_name
      @binary_package_version = binary_package_version

      @source_url = nil
      @source_path = nil

    end

    def find_source_package_page_link()
      # TODO: @Dragon add spider
      source_package_link = nil
    end

    def find_source_code_download_url()
      # TODO: @Dragon add spider
    end

    def download_source_code()
      # TODO: @Micfan, uncompress
      # TODO: configure a temp path to download and uncompress
      source_code_path = nil
    end

    # Entry
    def fetch_license_info_from_local_source(license_files_path)
      # TODO: @Micfan, move it common lib:
    end

  end
end

if __FILE__ == $0
  distribution = 'ubuntu'
  distro_series = 'trusty'
  name = 'anacron'
  version = '2.3-20ubuntu1'
  archi
  a = API::Launchpad.new(distribution, distro_series, name, version)
  p a.find_source_package_page_link

# ii  anacron                             2.3-20ubuntu1                    amd64        cron-like program that doesn't go by time
# ii  apparmor                            2.8.95~2430-0ubuntu5.3           amd64        User-space parser utility for AppArmor
# ii  apparmor-utils                      2.8.95~2430-0ubuntu5.3           amd64        Utilities for controlling AppArmor
# ii  apt                                 1.0.1ubuntu2.10                  amd64        commandline package manager
# ii  apt-utils                           1.0.1ubuntu2.10                  amd64        package management related utility programs
end
