# [Maven Repository Centre](https://maven.apache.org/repository/index.html)
# [API Guide](http://search.maven.org/#api)
require 'json'
require 'hashie'
require 'nokogiri'
require 'httparty'

module LicenseAuto
  class MavenCentralRepository

    # RESTful Sample
    # GET http://search.maven.org/solrsearch/select?q=g%3A%22com.google.inject%22&rows=20&wt=json
    REST_API = 'http://search.maven.org/solrsearch'


    def initialize(group_id, artifact_id, version, central_prefix='https://repo1.maven.org/maven2')
      @group_id = group_id
      @artifact_id = artifact_id
      @version = version
      @classifier = ''
      @central_prefix = central_prefix
    end

    # Example:
    # GET http://search.maven.org/solrsearch/select?q=g:"com.google.inject"+AND+a:"guice"&core=gav&rows=20&wt=json
    # @return:
    #     {
    #         "responseHeader":{
    #             "status":0,
    #             "QTime":0,
    #             "params":{
    #                 "fl":"id,g,a,v,p,ec,timestamp,tags",
    #                 "sort":"score desc,timestamp desc,g asc,a asc,v desc",
    #                 "indent":"off",
    #                 "q":"g:\"net.sourceforge.nekohtml\" AND a:\"nekohtml\" AND v:\"1.9.20\"",
    #                 "core":"gav",
    #                 "wt":"json",
    #                 "rows":"20",
    #                 "version":"2.2"
    #             }
    #         },
    #         "response":{
    #             "numFound":1,
    #             "start":0,
    #             "docs":[
    #                 {
    #                     "id":"net.sourceforge.nekohtml:nekohtml:1.9.20",
    #                     "g":"net.sourceforge.nekohtml",
    #                     "a":"nekohtml",
    #                     "v":"1.9.20",
    #                     "p":"jar",
    #                     "timestamp":1392301277000,
    #                     "tags":[
    #                         "html",
    #                         "parser",
    #                         "balancer"
    #                     ],
    #                     "ec":[
    #                         "-sources.jar",
    #                         "-javadoc.jar",
    #                         ".jar",
    #                         ".pom"
    #                     ]
    #                 }
    #             ]
    #         }
    #     }
    def select()
      url =
          if has_version
            "#{REST_API}/select?q=g:\"#{@group_id}\"+AND+a:\"#{@artifact_id}\"+AND+v:\"#{@version}\"&core=gav&rows=20&wt=json"
          else
            "#{REST_API}/select?q=g:\"#{@group_id}\"+AND+a:\"#{@artifact_id}\"&core=gav&rows=20&wt=json"
          end

      url = URI.escape(url)
      response = HTTParty.get(url)
      if response.code == 200
        Hashie::Mash.new(JSON.parse(response.body))
      else
        error = "CentralRepository select error: #{response}"
        LicenseAuto.logger.debug(url)
        LicenseAuto.logger.error(error)
        nil
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



    def get_package_pom(group, name, version)
      pom_url = make_pom_url(group, name, version)
      # http://stackoverflow.com/questions/25814210/opensslsslsslerror-ssl-connect-syscall-returned-5-errno-0-state-sslv3-read
      opts = {
          :ssl_version => 'TLSv1'
      }
      response = HTTParty.get(pom_url, options=opts)
      pom_str =
          if response.code == 200
            LicenseAuto.logger.debug("pom_url: #{pom_url}")
            response.body
          else
            LicenseAuto.logger.error("pom_url: #{pom_url}, #{response}")
          end
      [pom_url, pom_str]
    end

    # Example: https://repo1.maven.org/maven2/com/google/inject/guice/3.0/guice-3.0.pom
    def make_pom_url(group, name, version)
      central_body = [group.gsub(/\./, '/'), name, version].join('/')
      central_tail = "#{name}-#{version}.pom"
      [@central_prefix, central_body, central_tail].join('/')
    end

    def make_project_url
      if has_version
        "https://maven-repository.com/artifact/#{@group_id}/#{@artifact_id}/#{@version}"
      else
        "https://maven-repository.com/artifact/#{@group_id}/#{@artifact_id}"
      end
    end

    def has_version
      not @version.nil? and @version != ''
    end


    def get_license_info()
      license_info = LicenseAuto::LicenseInfoWrapper.new
      query_set = select

      unless query_set
        LicenseAuto.logger.error("Maven search result is empty")
      else
        query_set.response.docs.each {|doc|
          if doc.v == @version && doc.ec.include?('.pom')
            pom_url, pom_str = get_package_pom(@group_id, @artifact_id, @version)
            if pom_str
              pack_wrapper, license_files = parser_pom(pom_url, pom_str)
              license_info[:pack] = pack_wrapper
              license_info[:licenses] = license_files
            end
            break
          end
        }
      end
      license_info
    end

    # @return homepage, source_url, licenses_file
    def parser_pom(pom_url, pom_str)
      LicenseAuto.logger.debug("pom_str: #{pom_str}")
      doc = Nokogiri::XML(pom_str).remove_namespaces!

      # Source Code Manager
      scm_node = doc.xpath("/project/scm/url")
      source_url = if scm_node
                     scm_node.text
                   end

      homepage_node = doc.xpath("/project/url")
      homepage = if homepage_node
                   homepage_node.text
                 end

      pack_wrapper = LicenseAuto::PackWrapper.new(
          project_url: make_project_url,
          homepage: homepage,
          source_url: source_url
      )

      licenses_node = doc.xpath("//licenses/license")
      LicenseAuto.logger.debug("licenses: \n#{licenses_node.to_xml}")

      # Multi licenses: https://maven-repository.com/artifact/org.cryptacular/cryptacular/1.0
      license_files = licenses_node.map {|node|
        license_name = if node.xpath(".//name")
                         node.xpath(".//name").text
                       end
        license_url = if node.xpath(".//url")
                        node.xpath(".//url").text
                      end

        LicenseAuto.logger.debug(license_url)
        # TODO: find a license_text demo
        license_text = if not node.xpath(".//text").empty?
                         LicenseAuto.logger.debug('fuck')
                         LicenseAuto.logger.debug(node.xpath(".//text").text)
                         node.xpath(".//text").text
                       elsif license_url
                         LicenseAuto.logger.debug('fuck me')
                         LicenseAuto.logger.debug(license_url)
                         response = HTTParty.get(license_url)
                         response.body if response.code == 200
                       end

        LicenseAuto::LicenseWrapper.new(
            name: license_name,
            sim_ratio: 1.0,
            html_url: pom_url,
            download_url: license_url,
            text: license_text
        )
      }

      # Comment license text info: eg. https://repo1.maven.org/maven2/commons-io/commons-io/2.4/commons-io-2.4.pom
      if license_files.empty?
        comment_head_node = doc.xpath("/comment()[contains(., 'license')]")
        license_text = comment_head_node.to_xml
        license_files.push(
            LicenseAuto::LicenseWrapper.new(
                name: "UNKNOWN",
                sim_ratio: 1.0,
                html_url: pom_url,
                download_url: pom_url,
                text: license_text
            )
        )
      end

      [pack_wrapper, license_files]
    end
  end
end

if __FILE__ == $0
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
end
