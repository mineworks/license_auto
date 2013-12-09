require 'httparty'
require_relative '../conf/config'

module Misc

  def Misc.check_private_repo(where)
    pg_result = $conn.exec("select * from repo #{where}")

    pg_result.each {|r|
      source_url = r['source_url']
      $plog.debug("source_url: #{source_url}")
      response = HTTParty.get(source_url)

      priv = -1
      if response.code == 404
        require_relative './api'
        g = API::Github.new(source_url)
        commits = g.list_commits
        if commits != nil
          priv = 0
        end
      elsif response.code == 200
        priv = 1
      end
      $plog.debug("priv: #{priv}")

      update = $conn.exec_params("update repo set priv = $1 where source_url = $2", [priv, source_url])
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
  where = ' where 1=1 '
  Misc.check_private_repo(where)
end