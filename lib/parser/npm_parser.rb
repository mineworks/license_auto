class NpmParser
  def initialize(repo_path)
    @repo_path = repo_path
    @package_json_pattern = /package\.json$/i
  end

  def start

  end
end