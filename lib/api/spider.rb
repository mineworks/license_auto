require 'anemone'

module API

  class Spider
    def initialize(url)
      @url = url
    end

    def find_source_url()
      Anemone.crawl(@url)
    end


  end

end ### API
