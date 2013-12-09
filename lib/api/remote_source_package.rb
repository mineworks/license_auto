require 'httparty'
require 'anemone'
require 'rubygems/package'
require 'zlib'
require 'xz'
require 'open3'

require_relative '../../conf/config'
require_relative '../../extractor_ruby/License_recognition'
require_relative '../../lib/api/helper'
require_relative '../../lib/misc'

module API

  # TODO: replace this impl
  # Ruby mixin's way
  #
  # module Person
  #   def self.included x
  #     ms = x.instance_methods(false)
  #     [:xx, :yy, :zz].each do |xn|
  #       raise "Please IMPL #{xn} Interface" unless ms.include?(xn)
  #     end
  #   end
  # end
  #
  # class Customer
  #   def xx;end
  #   def yy;end
  #   def zz;end
  #   include Person
  # end
  #
  # c = Customer.new
  # c.xx
  # c.yy
  # c.zz
  class RemoteSourcePackage
    def initialize()
    end

    # OVERRIDE required
    # return: homepage, download_url
    def find_source_package_homepage_and_download_url()
      raise 'Method must be overridden'
    end

    def download_source_code(source_code_url)
      source_code_filename = source_code_url.split('/').last
      source_code_path = "#{LAUNCHPAD_SOURCE_DIR}/#{source_code_filename}"
      File.open(source_code_path, 'wb') do |f|
        f.binmode
        http_option = {
          :timeout => HTTPARTY_DOWNLOAD_TIMEOUT
        }
        http_proxy = Misc.get_http_proxy
        if http_proxy
          http_option[:http_proxyaddr] = http_proxy[:addr]
          http_option[:http_proxyport] = http_proxy[:port]
        end
        f.write(HTTParty.get(source_code_url, options=http_option).parsed_response)
      end

      return source_code_path
    end

    # Entry
    def fetch_license_info_from_local_source()
      license = nil
      license_url = nil
      license_text = nil
      source_package_download_url = nil

      # Attention, source package but binary package
      source_package_homepage, source_package_download_url = find_source_package_homepage_and_download_url
      $plog.debug("source_package_homepage: #{source_package_homepage}")
      $plog.debug("source_package_download_url: #{source_package_download_url}")
      if source_package_download_url
        source_code_path = download_source_code(source_package_download_url)
        $plog.debug("#{source_code_path}")
        if source_code_path
          reader = nil
          if source_code_path =~ API::FILE_TYPE_PATTERN[:tar_gz]
            reader = Zlib::GzipReader
          elsif source_code_path =~ API::FILE_TYPE_PATTERN[:tar_xz]
            reader = XZ::StreamReader
          elsif source_code_path =~ API::FILE_TYPE_PATTERN[:tar_bz2]
            # Bash script demo, MacOSX tar is not compatible
            # $ tar --version
            # tar (GNU tar) 1.27.1
            # >>> Copyright (C) 2013 Free Software Foundation, Inc.
            # >>> License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
            # >>> This is free software: you are free to change and redistribute it.
            # >> There is NO WARRANTY, to the extent permitted by law.
            # >> Written by John Gilmore and Jay Fenlason.
            # $ tar -tjvf bison_3.0.2.dfsg.orig.tar.bz2 | grep -i 'license\|copying\|readme' | awk '{ print $6 }'
            # $ tar -xj --file=bison_3.0.2.dfsg.orig.tar.bz2 bison-3.0.2.dfsg/COPYING
            # $ tar -xjO --file=bison_3.0.2.dfsg.orig.tar.bz2 bison-3.0.2.dfsg/COPYING
            # $ tar -xjO --file=bison_3.0.2.dfsg.orig.tar.bz2 bison-3.0.2.dfsg/COPYING -C /dev/null
            cmd_list_content = "tar -tjvf #{source_code_path} | grep -i 'license\\|copying' | awk '{ print $6 }'"
            # MacOSX
            # cmd_list_content = "tar -tjvf #{source_code_path} | grep -i 'license\\|copying' | awk '{ print $9 }'"
            $plog.debug(cmd_list_content)
            Open3.popen3(cmd_list_content) {|i,o,e,t|
              out = o.readlines
              error = e.readlines
              if error.length > 0
                # todo: move into exception.rb
                raise "decompress error: #{source_code_path}, #{error}"
              elsif out.length > 0
                out.each {|line|
                  license_file_path = line.gsub(/\n/, '')
                  if @root_license_only and !API::Helper.is_root_file(license_file_path)
                    next
                  end
                  cmd_read_content = "tar -xjO --file=#{source_code_path} #{license_file_path} -C /dev/null"
                  Open3.popen3(cmd_read_content) {|i,o,e,t|
                    out2 = o.read
                    error = e.readlines
                    if error.length > 0
                      raise "cmd_read_content error: #{source_code_path}, #{license_file_path}, #{error}"
                    elsif out2.length > 0
                      license_text = out2
                      license_url = license_file_path
                      $plog.debug(license_text)
                      break
                    end
                  }
                }
              end
            }
          else
            $plog.error("source_package_download_url: #{source_package_download_url}, can NOT be uncompressed.")
            return {}
          end

          if reader
            tar_extract = Gem::Package::TarReader.new(reader.open(source_code_path))
            tar_extract.rewind # The extract has to be rewinded after every iteration
            tar_extract.each do |entry|
              puts entry.full_name
              # puts entry.directory?
              # puts entry.file?
              # puts entry.read
              # Root dir files only
              if entry.directory? or !API::Helper.is_root_file(entry.full_name)
                next
              end

              if entry.file? and API::Helper.is_license_file(entry.full_name)
                license_url = entry.full_name
                license_text = entry.read

                $plog.debug(entry.full_name)
                $plog.debug(license_text)

                # TODO: parser license info
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

      if license_text
        license = License_recognition.new.similarity(license_text, STD_LICENSE_DIR)
      end
      {
        license: license,
        license_url: license_url,
        license_text: license_text,
        source_url: source_package_download_url,
        homepage: source_package_homepage
      }
    end

  end

  class Launchpad < RemoteSourcePackage
    # DOC: https://launchpad.net/+apidoc/1.0.html
    # The source code's license is no relation with which CPU architecture
    def initialize(distribution, distro_series, binary_package_name, binary_package_version, architecture='amd64',
                   root_license_only=true)
      @site_url = 'https://launchpad.net'
      @distribution = distribution
      @distro_series = distro_series
      @architecture = architecture
      @binary_package_name = binary_package_name
      @binary_package_version = binary_package_version
      @download_dir = @download_dir

      @source_url = nil
      @source_path = nil
      @root_license_only = root_license_only
    end

    def binary_package_link()
      binary_package_url = "#{@site_url}/#{@distribution}/#{@distro_series}/#{@architecture}/#{@binary_package_name}/#{@binary_package_version}"
    end

    # @OVERRIDED
    def find_source_package_homepage_and_download_url()
      homepage = _find_source_package_homepage
      download_url = nil
      if homepage
        download_url = _find_source_code_download_url(homepage)
      end
      return homepage, download_url
    end

    def _find_source_package_homepage()
      source_package_homepage = nil
      opts = {:discard_page_bodies => true, :depth_limit => 0}

      $plog.debug("binary_package_link: #{binary_package_link}")

      Anemone.crawl(binary_package_link, opts) do |anemone|
        anemone.on_every_page do |page|
          xpath = "//dd[@id='source']/a[1]"
          page.doc.xpath(xpath).each {|text|
            abs_href = text.css('/@href')
            if abs_href
              source_package_homepage = "#{@site_url}#{abs_href}"
              break
            end
          }
        end
      end
      return source_package_homepage
    end

    def _find_source_code_download_url(source_package_homepage)
      source_code_download_url = nil

      opts = {:discard_page_bodies => true, :depth_limit => 0}
      Anemone.crawl(source_package_homepage, opts) do |anemone|
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

    # def make_up_license_url()
    #   license_url = 'http://bazaar.launchpad.net/~ubuntu-branches/ubuntu/vivid/anacron/vivid/view/head:/COPYING'
    # end

  end

  class ManifestPackage < RemoteSourcePackage
    def initialize(source_code_download_url, root_license_only=true)
      @download_url = source_code_download_url
      @root_license_only = root_license_only
    end

    def find_source_package_homepage_and_download_url
      homepage = nil
      return homepage, @download_url
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

  # .bz2
  name = 'bzip2'
  version = '1.0.6-5'
  # a = API::Launchpad.new(distribution, distro_series, name, version)
  a = API::ManifestPackage.new('https://pivotal-buildpacks.s3.amazonaws.com/python/binaries/cflinuxfs2/libmemcache.tar.gz')
  license_info = a.fetch_license_info_from_local_source
  p license_info


# ii  anacron                             2.3-20ubuntu1                    amd64        cron-like program that doesn't go by time
# ii  apparmor                            2.8.95~2430-0ubuntu5.3           amd64        User-space parser utility for AppArmor
# ii  apparmor-utils                      2.8.95~2430-0ubuntu5.3           amd64        Utilities for controlling AppArmor
# ii  apt                                 1.0.1ubuntu2.10                  amd64        commandline package manager
# ii  apt-utils                           1.0.1ubuntu2.10                  amd64        package management related utility programs
end
