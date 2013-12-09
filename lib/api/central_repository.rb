require 'json'
require 'nokogiri'
require 'httparty'
require_relative '../../conf/config'

module API
  # DOC: http://search.maven.org/#api
  class CentralRepository
    def initialize(group_id, artifact_id, version)
      @group_id = group_id
      @artifact_id = artifact_id
      @version = version
      # @scope = scope
      # TODO: what is this field?
      @classifier = ''

      @api_url = "http://search.maven.org/solrsearch/select?q=g%3A%22com.google.inject%22&rows=20&wt=json"
    end

    # DOC: http://search.maven.org/solrsearch/select?q=g:"com.google.inject"+AND+a:"guice"&core=gav&rows=20&wt=json
    def select()
      url = "http://search.maven.org/solrsearch/select?q=g:\"#{@group_id}\"+AND+a:\"#{@artifact_id}\"&core=gav&rows=20&wt=json"
      url = URI.escape(url)
      $plog.debug(url)
      response = HTTParty.get(url)
      if response.code == 200
        query_set = JSON.parse(response.body)
      else
        raise "CentralRepository select error: #{response}"
      end
    end

    # Eg: http://search.maven.org/solrsearch/select?q=g:%22com.google.inject%22%20AND%20a:%22guice%22%20AND%20v:%223.0%22%20AND%20l:%22javadoc%22%20AND%20p:%22jar%22&rows=20&wt=json
    def advance_search
      url = "http://search.maven.org/solrsearch/select?q=g:\"#{@group_id}\" AND a:\"#{@artifact_id}\" AND v:\"#{@version}\" AND l:\"#{@classifier}\" AND p:\"jar\"&rows=20&wt=json"
      url = URI.escape(url)
      $plog.debug(url)
      response = HTTParty.get(url)
      if response.code == 200
        query_set = JSON.parse(response.body)
      else
        raise "CentralRepository select error: #{response}"
      end
    end

    #
    # POM: https://repo1.maven.org/maven2/com/google/inject/guice/3.0/guice-3.0.pom
    def get_package_pom(group, name, version)
      central_prefix = 'https://repo1.maven.org/maven2'
      central_body = [group.gsub(/\./, '/'), name.gsub(/\./, '/'), version].join('/')
      central_tail = "#{name}-#{version}.pom"
      pom_url = [central_prefix, central_body, central_tail].join('/')
      $plog.debug("pom_url: #{pom_url}")

      # http://stackoverflow.com/questions/25814210/opensslsslsslerror-ssl-connect-syscall-returned-5-errno-0-state-sslv3-read
      opts = {
        :ssl_version => 'TLSv1'
      }
      response = HTTParty.get(pom_url, options=opts)
      if response.code == 200
        pom = response.body
      else
        raise "CentralRepository get_package_pom error: #{response}"
      end
    end

    def get_license_info()
      license_info = {
        homepage: nil,
        source_url: nil,
        licenses: []
      }
      query_set = select

      if query_set
        query_set['response']['docs'].each {|d|
          version = d['v']
          ec = d['ec']
          if version == @version && ec.index('.pom')
            $plog.debug("version: #{version}")
            pom = get_package_pom(@group_id, @artifact_id, @version)
            # $plog.debug("pom: #{pom}")
            doc = Nokogiri::XML(pom).remove_namespaces!

            source_code_node = doc.xpath("/project/scm/url")
            source_url = source_code_node.text if source_code_node

            homepage_node = doc.xpath("/project/url")
            homepage = homepage_node.text if homepage_node

            xpath = "//licenses/license"
            licenses = doc.xpath(xpath)
            $plog.debug("licenses: #{licenses.to_xml}")

            # Multi licenses: https://maven-repository.com/artifact/org.cryptacular/cryptacular/1.0
            licenses.each {|node|
              license = license_url = license_text = nil
              if node.xpath(".//name")
                license = node.xpath(".//name").text
                # $plog.debug("license: #{license}")
              end
              license_url = node.xpath(".//url").text if licenses.xpath(".//url")

              # TODO: find a license_text demo
              # license_text = licenses.xpath(".//text").text if licenses.xpath(".//text")

              license_info[:licenses] << {
                license: license,
                license_url: license_url,
                license_text: license_text
              }
            }
            if licenses.size == 0
              $plog.debug("licenses.size: #{licenses.size}")
              # Comment license text info: eg. https://repo1.maven.org/maven2/commons-io/commons-io/2.4/commons-io-2.4.pom
              comment_node = doc.xpath("/comment()[contains(., 'license')]")
              if comment_node.size > 0
                license_text = comment_node.to_xml
                license_info[:licenses] << {
                  license: 'UNKNOWN',
                  license_url: nil,
                  license_text: license_text
                }
              end
            end

            break
          end
        }
      end
      license_info
    end
  end
end

if __FILE__ == $0
  # One license
  # item = {:group=>"net.sourceforge.nekohtml", :name=>"nekohtml", :version=>"1.9.20"}

  # Two license
  # item = {:group=>"org.cryptacular", :name=>"cryptacular", :version=>"1.0"}

  # License in comments
  item = {:group=>"commons-io", :name=>"commons-io", :version=>"2.4"}

  g, a, v = item.values
  c = API::CentralRepository.new(g, a, v)
  license_info = c.get_license_info
  $plog.debug("license_info #{license_info}")
end
