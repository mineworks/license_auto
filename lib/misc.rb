require  'find'
require 'json'
require 'httparty'
require_relative '../config/config'

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

  # TODO:
  def Misc.check_git_submodules(where)
    require_relative './api'
    # third_party = []
    # pg_result = $conn.exec("select * from repo #{where}")
    #
    # pg_result.each {|r|
      source_url = 'https://github.com/cloudfoundry-incubator/rep'
      $plog.debug("source_url: #{source_url}")

      g = API::Github.new(source_url)

      modules = g.get_gitmodules
      if modules
        # third_party.push(modules)
        $plog.debug("modules: #{mmodules}")
      end
      # update = $conn.exec_params("update repo set priv = $1 where source_url = $2", [priv, source_url])
    # }
  end

  def Misc.enqueue_packs(where)
    pg_result = $conn.exec("select * from pack #{where}")
    queue_name = 'license_auto.pack'
    $plog.debug("enqueue packs no: #{pg_result.ntuples}")
    pg_result.each {|p|
      pack_id = p['id'].to_i
      $rmq.publish(queue_name, {:pack_id => pack_id}.to_json, check_exist=true)
    }
  end

  def Misc.enqueue_repos(where, release_id)
    pg_result = $conn.exec("select * from repo #{where}")
    queue_name = 'license_auto.repo'
    $plog.debug("enqueue repos no: #{pg_result.ntuples}")
    pg_result.each {|repo|
      repo_id = repo['id'].to_i
      message = {
        :repo_id => repo_id,
        :release_id => release_id
      }
      $rmq.publish(queue_name, message.to_json, check_exist=true)
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

  class DirUtils
    attr_reader :path, :filenames
    def initialize(path)
      @path = path
      @filenames = []

      if File.exists?(path) and File.directory?(path)
        Find.find(path) do |filename|
          if File.file?(filename)
            @filenames.push(filename)
          end
        end
      else
        raise "Parameter Error: #{path}"
      end
    end

    def filter_filename(filename_pattern)
      result = []
      @filenames.each {|f|
        if f =~ filename_pattern
          result.push(f)
        end
      }
      result
    end
  end

end

if __FILE__ == $0
  # where = ' where 1=1 '
  # Misc.check_private_repo(where)

  where = ' where status < 30 '
  Misc.enqueue_packs(where)
  # Misc.check_private_repo(where)
  # third_party = Misc.check_git_submodules(where)

end