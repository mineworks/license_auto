require 'json'
require_relative '../../conf/config'
require_relative '../../lib/misc'
require_relative '../api/npm_registry'

class NpmParser
  def initialize(repo_path)
    @repo_path = repo_path
    @package_json_pattern = /#{repo_path}\/.*package\.json$/
  end

  def start
    pack_name_versions = []
    p @repo_path
    filenames = Misc::DirUtils.new(@repo_path).filter_filename(@package_json_pattern)
    filenames.each {|filename|
      $plog.debug(filename)
      j = JSON.parse(File.read(filename))
      deps = j['dependencies']
      dev_deps = j['devDependencies']
      [deps, dev_deps].each {|o|
        if o.nil?
          next
        end
        o.each {|pack_name,semver|
          # TODO:
          # if is_semver(semver)
          certain_version = API::NpmRegistry.new(pack_name, semver).chose_one_available_version(semver)
          pack_name_versions.push({'name' => pack_name, 'version' => certain_version})
        }
      }
    }
    pack_name_versions
  end
end

if __FILE__ == $0
  r = '/Users/mic/foo'
  p NpmParser.new(r).start
end