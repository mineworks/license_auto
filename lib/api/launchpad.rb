require 'httparty'

module API

  class Launchpad
    def initialize b_name = '',b_version = ''
      @binary_name = b_name
      @binary_version = b_version
      @launchpad_url = "https://launchpad.net/ubuntu/trusty/amd64/"
    end

    def launchpad(b_name = '',b_version = '')
      name    = "libp11-kit0"
      version = "0.20.2-2ubuntu2"
      url = @launchpad_url + name + "/" + version
      response = HTTParty.get(url)
      p response.body
      p "2222222222222222222"
      a = response.body =~ /<dd id="source">/
      p response.body[a,20]
      puts response.body.class
    end

  end


end



if __FILE__ == $0
  a = API::Launchpad.new
  a.launchpad

end

