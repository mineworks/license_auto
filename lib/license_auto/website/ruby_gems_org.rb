require 'gems'
require 'hashie'

require 'license_auto/website/github_com'
require 'license_auto/exceptions'


class RubyGemsOrg < Website

  URI = 'https://rubygems.org/'
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
        LicenseAuto.logger.error(e)
        return nil
      end
    end

    gem_info = get_gem_info

    raise LicenseAuto::PackageNotFound if gem_info.nil?

    license_info = LicenseAuto::LicenseInfoWrapper.new

    source_code_matcher = LicenseAuto::Matcher::SourceURL.new(gem_info.source_code_uri || gem_info.homepage_uri)
    github_matched = source_code_matcher.match_github_resource
    bitbucket_matched = source_code_matcher.match_bitbucket_resource

    if github_matched
      license_info = GithubCom.new(@package, github_matched[:owner], github_matched[:repo]).get_license_info
    elsif bitbucket_matched
      # TODO bitbucket_matched
    elsif gem_info.homepage_uri
      # TODO: HomepageSpider
      # LicenseAuto.logger.warn("TODO: HomepageSpider")
      # homepage_spider = HomepageSpider.new(gem_info.homepage_uri, @package.name)
      # source_code_uri = homepage_spider.get_source_code_uri
      # if source_code_uri
      #   LicenseAuto.logger.warn("TODO: call myself recursively")
      # else
      #   license_wrapper = homepage_spider.get_license_page
      #   LicenseAuto.logger.warn("TODO: HomepageSpider")
      # end

    elsif not gem_info.licenses.empty?
      license_files = gem_info.licenses.map {|license_name|
        LicenseAuto::LicenseWrapper.new(
            name: license_name,
            sim_ratio: 1.0,
            html_url: gem_info.project_uri,
            download_url: gem_info.project_uri,
            text: nil
        )
      }

      license_info[:licenses] = license_files
      LicenseAuto.logger.debug(license_info)
    end

    # TODO:
    pack_wrapper = LicenseAuto::PackWrapper.new(
        project_url: gem_info.project_uri,
        homepage: gem_info.homepage_uri,
        source_url: gem_info.source_code_uri || source_code_matcher.url
    )

    license_info[:pack] = pack_wrapper
    license_info
  end

  # @return eg. Hashie::Mash (19 elements)
  #     {
  #         "name":"diff-lcs",
  #         "downloads":42036753,
  #         "version":"1.2.5",
  #         "version_downloads":25578122,
  #         "platform":"ruby",
  #         "authors":"Austin Ziegler",
  #         "info":"Diff::LCS computes the difference between two Enumerable sequences using the\nMcIlroy-Hunt longest common subsequence (LCS) algorithm. It includes utilities\nto create a simple HTML diff output format and a standard diff-like tool.\n\nThis is release 1.2.4, fixing a bug introduced after diff-lcs 1.1.3 that did\nnot properly prune common sequences at the beginning of a comparison set.\nThanks to Paul Kunysch for fixing this issue.\n\nCoincident with the release of diff-lcs 1.2.3, we reported an issue with\nRubinius in 1.9 mode\n({rubinius/rubinius#2268}[https://github.com/rubinius/rubinius/issues/2268]).\nWe are happy to report that this issue has been resolved.",
  #         "licenses":[
  #             "MIT",
  #             "Perl Artistic v2",
  #             "GNU GPL v2"
  #         ],
  #         "metadata":{
  #
  #         },
  #         "sha":"a1d3dde665292317a883d319066792e3f0e6a24cade4bc4cc47605d27664c9ed",
  #         "project_uri":"https://rubygems.org/gems/diff-lcs",
  #         "gem_uri":"https://rubygems.org/gems/diff-lcs-1.2.5.gem",
  #         "homepage_uri":"http://diff-lcs.rubyforge.org/",
  #         "wiki_uri":null,
  #         "documentation_uri":"http://www.rubydoc.info/gems/diff-lcs/1.2.5",
  #         "mailing_list_uri":null,
  #         "source_code_uri":null,
  #         "bug_tracker_uri":null,
  #         "dependencies":{
  #             "development":[
  #                 {
  #                     "name":"hoe",
  #                     "requirements":"~> 3.7"
  #                 },
  #                 {
  #                     "name":"hoe-bundler",
  #                     "requirements":"~> 1.2"
  #                 },
  #                 {
  #                     "name":"hoe-doofus",
  #                     "requirements":"~> 1.0"
  #                 },
  #                 {
  #                     "name":"hoe-gemspec2",
  #                     "requirements":"~> 1.1"
  #                 },
  #                 {
  #                     "name":"hoe-git",
  #                     "requirements":"~> 1.5"
  #                 },
  #                 {
  #                     "name":"hoe-rubygems",
  #                     "requirements":"~> 1.0"
  #                 },
  #                 {
  #                     "name":"hoe-travis",
  #                     "requirements":"~> 1.2"
  #                 },
  #                 {
  #                     "name":"rake",
  #                     "requirements":"~> 10.0"
  #                 },
  #                 {
  #                     "name":"rdoc",
  #                     "requirements":"~> 4.0"
  #                 },
  #                 {
  #                     "name":"rspec",
  #                     "requirements":"~> 2.0"
  #                 },
  #                 {
  #                     "name":"rubyforge",
  #                     "requirements":">= 2.0.4"
  #                 }
  #             ],
  #             "runtime":[
  #
  #             ]
  #         }
  #     }
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