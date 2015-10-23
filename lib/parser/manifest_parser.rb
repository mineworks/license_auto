require 'yaml'

require_relative '../../lib/db'

class ManifestParser
  def initialize(repo_filepath, repo_id)
    @repo_filepath = repo_filepath
    @manifest_file_list = []
    ymls = api_get_repo_manifest_file_list(repo_id).values[0][0]
    if ymls != nil
      @manifest_file_list = ymls.gsub(' ', '').split(',')
    end
  end

  def start
    packs = []
    @manifest_file_list.each {|file_name|
      manifest_file_namepath = "#{@repo_filepath}/#{file_name}"
      dependencies = ManifestYAML.new(manifest_file_namepath).get_dependencies
      packs.concat(dependencies)
    }
    packs
  end
end

class ManifestYAML
  attr_reader :contents, :pack_language, :manifest_file_namepath

  def initialize(manifest_file_namepath)
    @contents = YAML.load_file(manifest_file_namepath)
    @pack_language = 'manifest.yml'
  end

  def get_dependencies()
    if @contents['dependencies'] == nil
      return []
    else
      return @contents['dependencies']
    end
  end

  def get_exclude_files()
    @contents['exclude_files']
  end

end

if __FILE__ == $0
  path = '/tmp/license_website/github.com/cloudfoundry/python-buildpack'
  id = 81
  p = ManifestParser.new(path, id)
  p.start
end