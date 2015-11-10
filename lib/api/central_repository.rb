require 'json'
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

    # DOC: http://search.maven.org/solrsearch/select?q=g:%22com.google.inject%22%20AND%20a:%22guice%22%20AND%20v:%223.0%22%20AND%20l:%22javadoc%22%20AND%20p:%22jar%22&rows=20&wt=json
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

    def get_package_meta()

    end
  end
end

if __FILE__ == $0
  id = 'org.aspectj:aspectjweaver:1.6.9'
  g, a, v = id.split(':')
  c = API::CentralRepository.new(g, a, v)
  # qs = c.advance_search
  qs = c.select
  # $plog.debug(qs['response']['docs'])
  qs['response']['docs'].each {|d|
    p d
  }
end
