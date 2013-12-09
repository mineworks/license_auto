require 'httparty'
require_relative '../conf/config'
require_relative './api'

module Misc

  def Misc.check_private_repo()
    pg_result = $conn.exec("select * from repo where is_private = false")

    pg_result.each {|r|
      source_url = r['source_url']
      $plog.debug("source_url: #{source_url}")
      response1 = HTTParty.get(source_url)

      is_private = false
      if response1.code == 404
        g = API::Github.new(source_url)
        commits = g.list_commits
        if commits != nil
          is_private = true
        end
      elsif response1.code == 200
        is_private = false
      end
      $plog.debug("is_private: #{is_private}")

      update = $conn.exec_params("update repo set is_private = $1 where source_url = $2", [is_private, source_url])
    }
  end

  def Misc.get_http_proxy
    http_proxy = ENV['license_auto_proxy']
    if http_proxy
      http_proxy = http_proxy.split(':')
      return {
        :addr => http_proxy[0],
        :port => http_proxy[1]
      }
    else
      return nil
    end
  end

end

if __FILE__ == $0
  Misc.check_private_repo
end