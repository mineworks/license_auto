# encoding: utf-8
require 'httparty'
require 'json'
require_relative '../../extractor_ruby/License_recognition'
require_relative '../misc'
require_relative '../api/rules'

module API

class Github
  # TODO: ref
  def initialize(repo_url)
    @repo_url = repo_url

    regex_group = format_url(repo_url)
    @protocol = regex_group[:protocol]
    @host = regex_group[:host]
    @owner = regex_group[:owner]
    @repo = regex_group[:repo]

    auth = {:username => ENV['github_username'], :password => ENV['github_password']}
    @http_option = {
      :basic_auth => auth
    }
    http_proxy = Misc.get_http_proxy
    if http_proxy
      @http_option[:http_proxyaddr] = http_proxy[:addr]
      @http_option[:http_proxyport] = http_proxy[:port]
    end
  end

  def format_url(repo_url)
    repo_url = repo_url.gsub(/\.git/, '')
    patten = API::SOURCE_URL_PATTERN[:github]
    result = patten.match(repo_url)
  end

  # DOC: https://developer.github.com/v3/repos/commits/#list-commits-on-a-repository
  def list_commits()
    commits = nil
    api_url = "https://api.github.com/repos/#{@owner}/#{@repo}/commits"
    $plog.info("api_url: #{api_url}")
    response = HTTParty.get(api_url, options=@http_option)
    if response.code == 200
      commits = JSON.parse(response.body)
    elsif response.code == 403
      $plog.error("!!! Github 403 Forbidden: #{response.body}")
    elsif response.code == 404
      $plog.error("!!! Github 404 Not found: #{response.body}")
    else
      $plog.error("!!! list_commits: #{response.body}")
    end
    commits
  end

  def last_commits()
    last = nil
    commits = list_commits
    if commits and commits.length > 0
      last = commits[0]
    end
    last
  end

  def list_contents(path='')
    contents = []
    api_url = "https://api.github.com/repos/#{@owner}/#{@repo}/contents/#{path}"
    $plog.info("list_contents: api_url: #{api_url}")
    response = HTTParty.get(api_url, options=@http_option)
    if response.code == 200
      contents = JSON.parse(response.body)
    elsif response.code == 403
      $plog.error('!!! Github 403 Forbidden.')
    else
      $plog.error("!!! response.code: #{response.code}, response.body: #{response.body}")
    end
    contents
  end

  def filter_license_contents()
    def is_license_file(filename)
      # TODO: add spell error regex
      return filename =~ /(license|copying|licence)+/i
    end

    def is_readme_file(filename)
      return filename =~ /readme/i
    end

    license_contents = {:license => [], :readme => []}
    root_contents = list_contents
    root_contents.each do |c|
      if c['type'] == 'file'
        if is_license_file(c['name'])
          license_contents[:license].push(c)
        end
        if is_readme_file(c['name'])
          license_contents[:readme].push(c)
        end
      end
    end
    license_contents
  end

  def get_license_info()
    license = license_url = license_text = nil
    license_contents = filter_license_contents
    $plog.info("license_contents: #{license_contents}")
    license_contents[:license].each do |c|
      download_url = c['download_url']
      $plog.info("License file 链接: #{download_url}")
      response = HTTParty.get(download_url, options=@http_option)
      if response.code == 200
        license_text = response.body
        license_url = download_url

        $plog.info("license_text: #{license_text}")

        # TODO: @Dragon, upgrade it to multi licenses
        license = License_recognition.new.similarity(license_text, "./extractor_ruby/Package_license")
        if license
          break
        end
      else
        # TODO: Use Dragon's HTML crawler, if API call limited
        $plog.error("!!! response.code: #{response.code}, download_url: #{download_url}")
      end
    end

    if license == nil
      license_contents[:readme].each do |c|
        # todo: @Dragon, readme parser
        # license = parse_license_info_from_readme
      end
    end

    {
      license: license,
      license_url: license_url,
      license_text: license_text
    }
  end
end

end ### API