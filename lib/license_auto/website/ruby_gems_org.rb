require 'gems'
require 'hashie'

require 'license_auto/website/github_com'
require 'license_auto/exceptions'


class RubyGemsOrg < Website

  HOST = 'rubygems.org'
  LANGUAGE = 'Ruby'

  GEM_NOT_FOUND = "This rubygem could not be found."

  def initialize(package)
    super(package)
  end

  # (Defaults to the latest version if no version is specified.)

  def get_license_info()
    if @package.version.nil?
      begin
        @package.version = get_latest_version['number']
      rescue Exception => e
        # TODO: what returned value is better?
        return nil
      end
    end

    gem_info = get_gem_info

    raise LicenseAuto::PackageNotFound if gem_info.nil?

    source_code_matcher = LicenseAuto::Matcher::SourceURL.new(gem_info.source_code_uri)

    github_matched = source_code_matcher.match_github_resource
    if github_matched
      license_info = GithubCom.new(@package, github_matched[:owner], github_matched[:repo]).get_license_info
    elsif false

    end

    # bitbucket_matched = source_code_matcher.match_bitbucket_resource()
    # if github_matched
    #   # TODO: bitbucket_matched
    # end
  end

  def get_gem_info()
    # TODO: Gems.info(@package.name, @package.version)
    gem_info = Gems.info(@package.name)
    gem_info =
        if gem_info == GEM_NOT_FOUND
          nil
        else
          Hashie::Mash.new(gem_info)
        end
  end

  # TODO: switch to https://github.com/rubygems/gems/issues/32#issuecomment-195180422
  # @return {
  #     "authors" => "David Heinemeier Hansson",
  #     "built_at" => "2016-03-07T00:00:00.000Z",
  #     "created_at" => "2016-03-07T22:33:22.563Z",
  #     "description" => "Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity. It encourages beautiful code by favoring convention over configuration.",
  #     "downloads_count" => 28113,
  #     "metadata" => {},
  #     "number" => "4.2.6",
  #     "summary" => "Full-stack web application framework.",
  #     "platform" => "ruby",
  #     "ruby_version" => ">= 1.9.3",
  #     "prerelease" => false,
  #     "licenses" => [
  #         [0] "MIT"
  #     ],
  #     "requirements" => [],
  #     "sha" => "a199258c0d2bae09993a6932c49df254fd66428899d1823b8c5285de02e5bc33"
  # }
  def get_latest_version()
    versions = Gems.versions(@package.name).reject { |v| v['prerelease'] }.first
    if versions == GEM_NOT_FOUND
      raise(GEM_NOT_FOUND)
    end

    versions.reject { |v| v['prerelease'] }.first
  end

  def download_gem()
  end
end