require 'json'
require 'nokogiri'
require 'httparty'
require_relative '../../config/config'

module API
  # DOC: http://search.maven.org/#api
  class MavenCentralRepository
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
      $plog.debug("api_url: #{url}")
      response = HTTParty.get(url)
      if response.code == 200
        query_set = JSON.parse(response.body)
      else
        raise "CentralRepository select error: #{response}"
      end
    end

    # POM: https://repo1.maven.org/maven2/com/google/inject/guice/3.0/guice-3.0.pom
    def get_package_pom(group, name, version)
      pom = nil

      central_prefix = 'https://repo1.maven.org/maven2'
      central_body = [group.gsub(/\./, '/'), name, version].join('/')
      central_tail = "#{name}-#{version}.pom"
      pom_url = [central_prefix, central_body, central_tail].join('/')
      # http://stackoverflow.com/questions/25814210/opensslsslsslerror-ssl-connect-syscall-returned-5-errno-0-state-sslv3-read
      opts = {
        :ssl_version => 'TLSv1'
      }
      response = HTTParty.get(pom_url, options=opts)
      if response.code == 200
        $plog.debug("pom_url: #{pom_url}")
        pom = response.body
      else
        $plog.error("CentralRepository get_package_pom error: pom_url: #{pom_url}, #{response}")
      end
      return pom_url, pom
    end

    def get_license_info()
      license_info = {
        homepage: nil,
        source_url: nil,
        licenses: [],
        project_url: nil,
        pom_url: nil
      }
      query_set = select

      if query_set
        query_set['response']['docs'].each {|d|
          version = d['v']
          ec = d['ec']
          if version == @version && ec.index('.pom')
            license_info[:project_url] = "https://maven-repository.com/artifact/#{@group_id}/#{@artifact_id}/#{@version}"
            pom_url, pom = get_package_pom(@group_id, @artifact_id, @version)
            if pom
              license_info[:pom_url] = pom_url

              # $plog.debug("pom: #{pom}")
              doc = Nokogiri::XML(pom).remove_namespaces!

              source_code_node = doc.xpath("/project/scm/url")
              license_info[:source_url] = source_code_node.text if source_code_node

              homepage_node = doc.xpath("/project/url")
              license_info[:homepage] = homepage_node.text if homepage_node

              xpath = "//licenses/license"
              licenses = doc.xpath(xpath)
              $plog.debug("licenses: #{licenses.to_xml}")

              # Multi licenses: https://maven-repository.com/artifact/org.cryptacular/cryptacular/1.0
              licenses.each {|node|
                license = nil
                license_url = nil
                license_text = nil
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


  'aopalliance:aopalliance:1.0'
  'cglib:cglib-nodep:3.1'
  'com.beust:jcommander:1.48'
  'com.google.guava:guava:18.0'
  'com.google.inject:guice:no_aop:4.0'
  'com.jayway.awaitility:awaitility:1.6.3'
  'javax.inject:javax.inject:1'
  'junit:junit:4.10'
  'org.apache.ant:ant:1.7.0'
  'org.apache.ant:ant-launcher:1.7.0'
  'org.assertj:assertj-core:3.1.0'
  'org.beanshell:bsh:2.0b4'
  'org.hamcrest:hamcrest-core:1.3'
  'org.hamcrest:hamcrest-library:1.3'
  'org.objenesis:objenesis:2.1'
  'org.testng:testng:6.9.6'
  'org.yaml:snakeyaml:1.15'

  begin
    i = 'javax.inject:javax.inject:1'
    g, a, v = i.split(':')
    c = API::MavenCentralRepository.new(g, a, v)

    license_info = c.get_license_info
    $plog.debug("license_info #{license_info}")

    if license_info[:licenses].size == 1
    elsif license_info[:licenses].size > 1
      $plog.debug("#{g}:#{a}:#{v} -- has multi license")
    end

  rescue Exception => e
    $plog.error("#{g}:#{a}:#{v}, #{e}")
  end

  $plog.info("results: #{license_info}")
end
