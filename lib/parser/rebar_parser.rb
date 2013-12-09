require 'json'
require 'open3'
require_relative '../../config/config'
require_relative '../../lib/misc'
require_relative '../api'

class ErlangParser

  def initialize(repo_path)
    @repo_path = repo_path
    @rebar_config_pattern = /#{repo_path}\/rebar\.config$/
  end

  def start
    packs = []
    filenames = Misc::DirUtils.new(@repo_path).filter_filename(@rebar_config_pattern)
    if filenames.size == 1
      cmd = "rebar list-deps"
      Dir.chdir(@repo_path) {
        Open3.popen3(cmd) {|i,o,e,t|
          output = o.read
          error = e.read
          if error.length > 0
            packs = filter_items(error)
          elsif output.length > 0
            packs = filter_items(output)
          else
            raise "#{self.class}.list_projects error error: #{cmd}, #{error}"
          end
        }
      }
    end
    packs
  end

  def filter_items(output)
    packs = []
    output = output.gsub(/\s/, '').gsub(/ERROR:Missingdependencies:/, '').split(/\},\{/)
    output.each {|d|
      pattern = /dep,\"(?<local_dir>.+)\",(?<app_name>.+),\[*\],\{(?<repository_type>(git|hg|bzr)),\"(?<location_url>.*)\",\"(?<ref>.+)\"}/
      matched = pattern.match(d)
      if matched
        # repository_type = matched[:repository_type]
        source_url = matched[:location_url]
        pack_version = matched[:ref]
        if source_url =~ API::SOURCE_URL_PATTERN[:github]
          pack_name = API::Github.new(source_url).repo
          source_url = source_url.gsub(/git:\/\//, 'https://')
        else
          pack_name = source_url
        end
        packs.push({
           'name' => pack_name,
           'version' => pack_version,
           'uri' => source_url
        })
      end
    }
    packs
  end
end
