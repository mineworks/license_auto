require 'open-uri'

require 'license_auto/license/similarity'

class HomepageSpider

  SOURCE_CODE_URI_PATTERN = /(github\.com|bitbucket\.org)\/.*\/#{@package.name}/

  def initialize(homepage, pack_name)

  end

  # Eg. 2
  # Name:
  #     sequel
  # Version:
  #     4.32.0
  # Lang:
  #     rubygems.org
  # http://sequel.jeremyevans.net/development.html
  # -> https://github.com/jeremyevans/sequel/
  def get_source_code_uri

  end

  # Eg.
  # homepage = 'https://www.sqlite.org/'
  # pack_name = 'sqlite3'
  # spider = HomepageSpider.new(homepage, pack_name)
  # license_page = spider.get_license_page
  # license_wrapper = LicenseWrapper.new(license_page)
  # @return
  # license_wrapper = {
  #     html_url: 'https://www.sqlite.org/copyright.html',
  #     text: 'xxx'
  # }
  def get_license_page
    html_url = 'https://www.sqlite.org/copyright.html'
    text = open(html_url).read
    license_name, sim_ratio = LicenseAuto::Similarity.new(text).most_license_sim
    license_wrapper = LicenseWrapper.new(
        html_url: html_url,
        text: text,
        name: license_name,
        sim_ratio: sim_ratio
    )
  end

end