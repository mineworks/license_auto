require "httparty"
require_relative '../../lib/misc'

module API

  class Spider
    def initialize(homepage_url, pack_name)
      @homepage_url = homepage_url
      @pack_name = pack_name
      http_proxy = Misc.get_http_proxy
      @http_option = {}
      if http_proxy
        @http_option[:http_proxyaddr] = http_proxy[:addr]
        @http_option[:http_proxyport] = http_proxy[:port]
      end
    end

    def find_source_url()
      response = HTTParty.get(@homepage_url, options=@http_option)
      if response.code == 200
        body = response.licenses
        # TODO: author name valid
        pattern = /(http[s]?:\/\/(github\.com|bitbucket\.org)\/|git@(github\.com|bitbucket\.org):)(?<author>.+?)\/#{@pack_name}/i
        match_result = pattern.match(body)
        if match_result
          author = match_result['author']
          if author != nil
            source_url = "https://github.com/#{author}/#{@pack_name}"
            return source_url
          end
        end
      else
        # TODO: 404
      end
    end

  end

end ### API

if __FILE__ == $0
  url = "http://www.rubyonrails.org"
  pack_name = 'httparty'
  s = API::Spider.new(url, pack_name)
  source_url = s.find_source_url
  p source_url
end
