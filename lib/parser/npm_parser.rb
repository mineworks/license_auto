require 'json'
require 'open3'
require_relative '../../conf/config'
require_relative '../../lib/misc'
require_relative '../api/npm_registry'
require_relative '../api/pattern'

class NpmParser
  def initialize(repo_path)
    @repo_path = repo_path
    @package_json_pattern = /#{repo_path}\/.*package\.json$/
  end

  def start
    pack_name_versions = []
    filenames = Misc::DirUtils.new(@repo_path).filter_filename(@package_json_pattern)
    filenames.each {|filename|
      $plog.debug(filename)
      j = JSON.parse(File.read(filename))
      deps = j['dependencies']
      dev_deps = j['devDependencies']
      [deps, dev_deps].each {|d|
        if d.nil?
          next
        end
        d.each {|pack_name,semver|
          if _is_valid_semver(semver)
            certain_version = API::NpmRegistry.new(pack_name, semver).chose_one_available_version(semver)
            pack = {'name' => pack_name, 'version' => certain_version}
            pack_name_versions.push(pack)
          elsif semver =~ API::SOURCE_URL_PATTERN[:npm_urls]
            r = API::SOURCE_URL_PATTERN[:npm_urls].match(semver)
            # TODO: save by original type
            if r['host'] =~ API::SOURCE_URL_PATTERN[:github_dot_com]
              source_url = "https://github.com/#{r['owner']}/#{r['repo']}"
            else
              source_url = semver
            end
            if r['ref'] == nil
              version = 'master'
            else
              version = r['ref']
            end
            pack = {
              'name' => pack_name,
              'version' => version,
              'uri' => source_url
            }
            pack_name_versions.push(pack)
          else
            raise "Unknown semver pattern: #{semver}, pack_name"
          end
        }
      }
    }
    pack_name_versions
  end

  # DOC: https://github.com/npm/node-semver/blob/5f89ecbe78145ad0b501cf6279f602a23c89738d/test/index.js#L461
  def _is_valid_semver(semver)
    is_valid = false
    cmd = "node -e \"var semver = require('semver'); var valid = semver.validRange('#{semver}'); console.log(valid)\""
    $plog.debug(cmd)
    Open3.popen3(cmd) {|i,o,e,t|
      out = o.readlines
      error = e.readlines
      if error.length > 0
        $plog.error(error)
        raise "node -e evaluate script error: #{cmd}, #{error}"
      elsif out.length > 0
        is_valid = out[0].gsub(/\n/,'') != 'null'
      end
    }
    is_valid
  end
end
