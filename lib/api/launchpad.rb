require 'httparty'
require 'anemone'
require 'rubygems/package'
require 'zlib'
require 'xz'

require_relative '../../conf/config'
require_relative '../../lib/api/helper'

module API
  class Launchpad
    # DOC: https://launchpad.net/+apidoc/1.0.html
    # The source code's license is no relation with which CPU architecture
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

    def binary_package_link()
      binary_package_url = "#{@site_url}/#{@distribution}/#{@distro_series}/#{@architecture}/#{@binary_package_name}/#{@binary_package_version}"
    end

    def find_source_package_page_link()
      source_package_link = nil

      # TODO: @Micfan, abstract it out
      opts = {:discard_page_bodies => true, :depth_limit => 0}

      $plog.debug("binary_package_link: #{binary_package_link}")

      Anemone.crawl(binary_package_link, opts) do |anemone|
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
          target_links = page.doc.xpath(xpath)
          if target_links.size == 0
            # Eg. https://launchpad.net/ubuntu/+source/wireless-crda/1.16
            xpath = "//div[@id='source-files']/table/tbody/tr/td/a[not(contains(@href, '.dsc'))]"
            target_links = page.doc.xpath(xpath)
          end
          # puts target_links
          target_links.each {|text|
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
      source_code_filename = source_code_url.split('/').last
      source_code_path = "#{LAUNCHPAD_SOURCE_DIR}/#{source_code_filename}"
      File.open(source_code_path, 'wb') do |f|
        f.binmode
        f.write(HTTParty.get(source_code_url).parsed_response)
      end

      return source_code_path
    end

    def make_up_license_url()
      license_url = 'http://bazaar.launchpad.net/~ubuntu-branches/ubuntu/vivid/anacron/vivid/view/head:/COPYING'
    end

    # Entry
    def fetch_license_info_from_local_source()
      # TODO: @Micfan, move it common lib:
      license = nil
      license_url = nil
      license_text = nil
      source_code_download_url = nil

      source_package_page_link = find_source_package_page_link
      if source_package_page_link

        $plog.debug("source_package_page_link: #{source_package_page_link}")

        source_code_download_url = find_source_code_download_url(source_package_page_link)
        if source_code_download_url
          source_code_path = download_source_code(source_code_download_url)
          if source_code_path
            # TODO: move into pattern.rb
            if source_code_path =~ API::FILE_TYPE_PATTERN[:tar_gz]
              reader = Zlib::GzipReader
            elsif source_code_path =~ API::FILE_TYPE_PATTERN[:tar_xz]
              reader = XZ::StreamReader
            elsif source_code_path =~ API::FILE_TYPE_PATTERN[:tar_bz2]
              # TODO: @Dragon, format: bz2 (tar, rar, zip, 7z)
              reader = File
            else
              $plog.error("source_code_download_url: #{source_code_download_url}, can NOT be uncompressed.")
              return {}
            end
            tar_extract = Gem::Package::TarReader.new(reader.open(source_code_path))
            tar_extract.rewind # The extract has to be rewinded after every iteration
            tar_extract.each do |entry|
              # puts entry.directory?
              # puts entry.file?
              # puts entry.read

              # Root dir files only
              if entry.directory? or entry.full_name.split('/').size > 2
                next
              end

              if entry.file? and API::Helper.is_license_file(entry.full_name)
                license_url = entry.full_name
                license_text = entry.read

                $plog.debug(entry.full_name)
                $plog.debug(license_text)

                # TODO: parser license info
                license = License_recognition.new.similarity(license_text, STD_LICENSE_DIR)
                break
              end

              # TODO:
              # if entry.file? and API::Helper.is_readme_file(entry.full_name)
              #   puts entry.full_name
              #   # puts entry.read
              #   # TODO: readme parser license info
              #   break
              # end

            end
            tar_extract.close ### to abstract out
          end
        end
      end
      {
        license: license,
        license_url: license_url,
        license_text: license_text,
        source_url: source_code_download_url,
        homepage: source_package_page_link
      }
    end

  end
end

if __FILE__ == $0
  distribution = 'ubuntu'
  distro_series = 'trusty'
  name = 'anacron'
  version = '2.3-20ubuntu1'

  name = 'sg3-utils'
  version = '1.36-1ubuntu1'

  name = 'wireless-crda'
  version = '1.16'
  a = API::Launchpad.new(distribution, distro_series, name, version)
  license_info = a.fetch_license_info_from_local_source


# ii  anacron                             2.3-20ubuntu1                    amd64        cron-like program that doesn't go by time
# ii  apparmor                            2.8.95~2430-0ubuntu5.3           amd64        User-space parser utility for AppArmor
# ii  apparmor-utils                      2.8.95~2430-0ubuntu5.3           amd64        Utilities for controlling AppArmor
# ii  apt                                 1.0.1ubuntu2.10                  amd64        commandline package manager
# ii  apt-utils                           1.0.1ubuntu2.10                  amd64        package management related utility programs
end
