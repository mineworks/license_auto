require 'httparty'
require 'anemone'
require 'rubygems/package'
require 'zlib'

require_relative '../../conf/config'
require_relative '../../lib/api/helper'

module API
  class Launchpad
    # DOC: https://launchpad.net/+apidoc/1.0.html
    def initialize(distribution, distro_series, binary_package_name, binary_package_version, architecture='amd64')
      @site_url = 'https://launchpad.net'
      @distribution = distribution
      @distro_series = distro_series
      @architecture = architecture
      @binary_package_name = binary_package_name
      @binary_package_version = binary_package_version

      @source_url = nil
      @source_path = nil
    end

    def find_source_package_page_link()
      source_package_link = nil
      binary_package_url = "#{@site_url}/#{@distribution}/#{@distro_series}/#{@architecture}/#{@binary_package_name}/#{@binary_package_version}"

      # TODO: @Micfan, abstract it out
      opts = {:discard_page_bodies => true, :depth_limit => 0}
      Anemone.crawl(binary_package_url, opts) do |anemone|
        anemone.on_every_page do |page|
          xpath = "//dd[@id='source']/a[1]"
          page.doc.xpath(xpath).each {|text|
            abs_href = text.css('/@href')
            if abs_href
              source_package_link = "#{@site_url}#{abs_href}"
              break
            end
          }
        end
      end
      return source_package_link
    end

    def find_source_code_download_url(source_package_link)
      # TODO: @Dragon add spider
      source_code_download_url = nil

      opts = {:discard_page_bodies => true, :depth_limit => 0}
      Anemone.crawl(source_package_link, opts) do |anemone|
        anemone.on_every_page do |page|
          xpath = "//div[@id='source-files']/table/tbody/tr/td/a[contains(@href, '.orig.')]"
          page.doc.xpath(xpath).each {|text|
            full_href = text.attr('href')
            if full_href
              source_code_download_url = full_href
              break
            end
          }
        end
      end
      return source_code_download_url
    end

    # TODO: @Micfan, fetch file from Launchpad.net API
    def download_source_code(source_code_url)
      # TODO: @Micfan, uncompress
      # TODO: configure a temp path to download and uncompress

      source_code_filename = source_code_url.split('/').last
      source_code_path = "#{AUTO_ROOT}/#{source_code_filename}"
      File.open(source_code_path, 'wb') do |f|
        f.binmode
        f.write(HTTParty.get(source_code_url).parsed_response)
      end

      return source_code_path
    end

    # Entry
    def fetch_license_info_from_local_source()
      # TODO: @Micfan, move it common lib:
      source_package_page_link = find_source_package_page_link
      if source_package_page_link
        source_code_download_url = find_source_code_download_url(source_package_page_link)
        if source_code_download_url
          source_code_path = download_source_code(source_code_download_url)
          if source_code_path
            if source_code_path =~ /tar\.gz$/
              reader = Zlib::GzipReader
            else
              # TODO: format: tar, gx (rar, zip, 7z)
              return nil
            end
            tar_extract = Gem::Package::TarReader.new(reader.open(source_code_path))
            tar_extract.rewind # The extract has to be rewinded after every iteration
            tar_extract.each do |entry|

              # Only indent the root dir license file
              if entry.file? and API::Helper.is_license_file(entry.full_name)
                puts entry.full_name
                puts entry.read
              end

              if entry.file? and API::Helper.is_readme_file(entry.full_name)
                puts entry.full_name
                puts entry.read
                # TODO: readme
              end

              # TODO: 2 dir
              # puts entry.directory?
              # puts entry.file?
              # puts entry.read
            end
            tar_extract.close
          else
            # nil
          end
        else
          # nil
        end
      else
        # nil
      end
    end

  end
end

if __FILE__ == $0
  distribution = 'ubuntu'
  distro_series = 'trusty'
  name = 'anacron'
  version = '2.3-20ubuntu1'
  a = API::Launchpad.new(distribution, distro_series, name, version)
  license_info = a.fetch_license_info_from_local_source

  # url = "https://launchpad.net/ubuntu/+source/anacron/2.3-20ubuntu1"
  # source_code_url = 'https://launchpad.net/ubuntu/+archive/primary/+files/anacron_2.3.orig.tar.gz'
  # a.find_source_code_download_url(url)


# ii  anacron                             2.3-20ubuntu1                    amd64        cron-like program that doesn't go by time
# ii  apparmor                            2.8.95~2430-0ubuntu5.3           amd64        User-space parser utility for AppArmor
# ii  apparmor-utils                      2.8.95~2430-0ubuntu5.3           amd64        Utilities for controlling AppArmor
# ii  apt                                 1.0.1ubuntu2.10                  amd64        commandline package manager
# ii  apt-utils                           1.0.1ubuntu2.10                  amd64        package management related utility programs
end
