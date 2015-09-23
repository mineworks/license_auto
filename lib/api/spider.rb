require "httparty"

module API

  class Spider
    def initialize(url, pack_name)
      @url = url
      @pack_name = pack_name
    end

    def find_source_url()
      response = HTTParty.get(@url)
      if response.code == 200
        body = response.body
        # TODO: author name valid
        pattern = /(http[s]?:\/\/(github\.com|bitbucket\.org)\/|git@(github\.com|bitbucket\.org):)(?<author>.+?)\/#{@pack_name}/
      
        match_result = pattern.match(body)
        author = match_result['author']
        # p author
        if author != nil
          source_url = "https://github.com/#{author}/#{@pack_name}"
          return source_url
        end
      else
        # TODO: 404
      end
    end

  end

end ### API

if __FILE__ == $0
  url = 'http://johnnunemaker.com/httparty/'
  pack_name = 'httparty'
  s = API::Spider.new(url, pack_name)
  source_url = s.find_source_url
  p source_url
end
