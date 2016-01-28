# encoding: utf-8
require "base64"
require 'httparty'
require 'json'
require_relative '../../extractor_ruby/License_recognition'
require_relative '../misc'
require_relative '../api/pattern'
require_relative './helper'

module API

class Github
  attr_reader :ref, :owner, :repo, :host, :repo_url

  def initialize(repo_url, db_ref=nil)
    ssh_pattern = /^git@/
    git_pattern = /^git:\/\//
    if repo_url =~ git_pattern
      repo_url = repo_url.gsub(/^git:\/\//, 'https://')
    elsif repo_url =~ ssh_pattern
      repo_url = repo_url.gsub(/:/, '/').gsub(/^git@/, 'https://')
    end
    @repo_url = repo_url

    repo_url = repo_url.gsub(/\.git$/, '')
    repo_url_pattern = API::SOURCE_URL_PATTERN[:github]
    # FIXME: error: http://github.com/TooTallNate/ansi.js -> http://github.com/TooTallNate/ansi
    regex_group = repo_url_pattern.match(repo_url)
    @protocol = regex_group[:protocol]
    @host = regex_group[:host]
    @owner = regex_group[:owner]
    @repo = regex_group[:repo]

    @http_option = Github.get_http_option
    @ref = _match_a_ref(db_ref)
  end

  def self.get_http_option
    # TODO: config file
    auth = {:username => ENV['github_username'], :password => ENV['github_password']}
    http_option = {
      :basic_auth => auth
    }
    http_proxy = Misc.get_http_proxy
    if http_proxy
      http_option[:http_proxyaddr] = http_proxy[:addr]
      http_option[:http_proxyport] = http_proxy[:port]
    end
    http_option
  end

  def _match_a_ref(db_ref)
    _ref = nil
    # Golang version is a git sha
    if db_ref == nil or db_ref.size == 40
      return db_ref
    else
      # version number
      all_refs = list_all_tags
      # TODO: - + *
      version_pattern = /[vV]?#{db_ref.gsub(/\./, '\.').gsub(/\//, '\/')}$/i
      all_refs.each {|r|
        ref = r['ref']
        ref_name = ref.split('/').last
        if ref_name =~ version_pattern
          $plog.debug(ref_name)
          return ref_name
        end
      }
      return get_default_branch()
    end
  end

  # DOC: https://developer.github.com/v3/git/refs/
  def list_all_tags
    refs = []
    api_url = "https://api.github.com/repos/#{@owner}/#{@repo}/git/refs/tags"
    $plog.info("api_url: #{api_url}")
    response = HTTParty.get(api_url, options=@http_option)
    if response.code == 200
      refs = JSON.parse(response.body)
    elsif response.code == 403
      $plog.error("!!! Github 403 Forbidden: #{response}")
    elsif response.code == 404
      $plog.error("!!! Github 404 Not found: #{response}")
    else
      $plog.error("!!! list_all_references() response: #{response}")
    end
    refs
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
      $plog.error("!!! Github 403 Forbidden: #{response}")
    elsif response.code == 404
      $plog.error("!!! Github 404 Not found: #{response}")
    else
      $plog.error("!!! list_commits() response: #{response}")
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

  # DOC: https://developer.github.com/v3/repos/#get
  def get_repo_info()
    api_url = "https://api.github.com/repos/#{@owner}/#{@repo}"
    response = HTTParty.get(api_url, options=@http_option)
    if response.code == 200
      contents = JSON.parse(response.body)
      # p contents
    elsif response.code == 403
      $plog.error('!!! Github 403 Forbidden.')
    else
      $plog.error("!!! response.code: #{response.code}, response.body: #{response.body}")
    end
  end

  def switch_to_default_branch
    default_branch = get_default_branch
    switched = default_branch != @ref
    @ref = default_branch
    return default_branch, switched
  end

  def get_default_branch
    repo_info = get_repo_info
    if repo_info
      repo_info['default_branch']
    else
      nil
    end
  end

  def self.convert_htmlpage_to_raw_url(html_page)
    raw_url = nil
    content = nil
    api_url = "#{html_page}?raw=true"

    response = HTTParty.get(api_url, options=get_http_option)
    # response = HTTParty.get(api_url, follow_redirects: true)
    # $plog.debug(response.code)
    if response.code == 200
      raw_url = response.request.last_uri.to_s
      $plog.debug(raw_url)
      content = response.body
    end

    return raw_url, content
  end

  # DOC: https://developer.github.com/v3/repos/contents/#get-contents
  def list_contents(path='')
    contents = []
    api_url = "https://api.github.com/repos/#{@owner}/#{@repo}/contents/#{path}"
    if @ref
      api_url += "?ref=#{@ref}"
    end

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

  def filter_license_contents(path)
    license_contents = {:license => [], :readme => []}
    root_contents = list_contents(path)
    root_contents.each do |c|
      if c['type'] == 'file'
        if API::Helper.is_license_file(c['name'])
          license_contents[:license].push(c)
        end
        if API::Helper.is_readme_file(c['name'])
          license_contents[:readme].push(c)
        end
      end
    end
    license_contents
  end

  def filter_notice_contents(path = '')
    notice_contents = []
    root_contents = list_contents(path)
    root_contents.each do |c|
      if c['type'] == 'file'
        if API::Helper.is_notice_file(c['name'])
          notice_contents.push(c)
        end
      end
    end
    notice_contents
  end

  def get_gitmodules
    gitmodules = nil
    root_contents = list_contents(path)
    root_contents.each do |c|
      if c['type'] == 'file' and c['name'] == 'gitmodules'
        gitmodules = c
      end
    end
    gitmodules
  end

  # DOC: https://developer.github.com/v3/licenses/#get-the-contents-of-a-repositorys-license
  def api_get_a_repositorys_license
    license = license_url = license_text = nil
    api_url = "https://api.github.com/repos/#{@owner}/#{@repo}/license"
    if @ref
      api_url += "?ref=#{@ref}"
    end

    $plog.info("api_get_a_repositorys_license: api_url: #{api_url}")
    response = HTTParty.get(api_url, options=@http_option)
    if response.code == 200
      contents = JSON.parse(response.body)
      license, license_url = contents['license']['name'], contents['download_url']

      if contents['encoding'] == 'base64'
        license_text = Base64.decode64(contents['content'])
      else
        license_text = 'DECODING ERROR!'
      end
    elsif response.code == 403
      $plog.error('!!! Github 403 Forbidden.')
    else
      $plog.error("!!! response.code: #{response.code}, response.body: #{response.body}")
    end

    {
      license: license,
      license_url: license_url,
      license_text: license_text
    }
  end

  def get_license_info()
    # license_info = api_get_a_repositorys_license
    # if license_info[:license_url] != nil
    #   return license_info
    # end
    license = license_url = license_text = nil
    license_contents = filter_license_contents(path='')
    #$plog.debug("license_contents: #{license_contents}")
    license_contents[:license].each do |c|
      download_url = c['download_url']
      $plog.info("License file 链接: #{download_url}")
      response = HTTParty.get(download_url, options=@http_option)
      if response.code == 200
        license_text = response.body
        license_url = download_url

        $plog.info("license_text: #{license_text}")

        # TODO: @Dragon, upgrade it to multi licenses
        license = License_recognition.new.similarity(license_text, STD_LICENSE_DIR)
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
        $plog.debug(" README file name: #{c['name']}")
        if File.extname(c['name']) =~ /\.(rdoc|txt|text)$/i
          regular_start = /^==\s*(copying|license){1}:*/i
          regular_end   = /^==/
        elsif File.extname(c['name']) =~ /\.(md|markdown)/i
          regular_start = /^#+\s*(copying|license){1}:*/i
          regular_end   = /^#+/
        else
          next
        end
        download_url = c['download_url']
        $plog.info("readme file 链接: #{download_url}")
        response = HTTParty.get(download_url, options=@http_option)
        if response.code == 200
          readme_text = response.body # type : String
          readme_url = download_url
          $plog.info("readme_text: #{readme_text}")
          start_flag = nil
          end_flag   = nil
          readme_text.each_line("\n") do |line|
            if line.encode('UTF-8', :invalid => :replace, :undef => :replace) =~ regular_start
              a = readme_text =~ /#{line}/
              start_flag = a + line.size
            elsif nil != start_flag
              if line =~ regular_end
                end_flag = readme_text =~ /#{line}/
              end
            end
          end
          if start_flag.class == Fixnum and end_flag == nil
            end_flag = readme_text.size
          end

          if start_flag != nil
            #p "readme license info:"
            readme_license =  readme_text[start_flag,end_flag - start_flag]
            license = License_recognition.new.similarity(readme_license, STD_LICENSE_DIR)
            license_text = readme_license
            license_url = download_url
            break
          else
          end

          if license
            break
          end
        else
          # TODO: Use Dragon's HTML crawler, if API call limited
          $plog.error("!!! response.code: #{response.code}, download_url: #{download_url}")
        end

      end
    end

    if license == 'Apache2.0'
      license_text = nil
      items = []
      notice_contents = filter_notice_contents
      notice_contents.each do |c|
        download_url = c['download_url']
        $plog.info("License file 链接: #{download_url}")
        response = HTTParty.get(download_url, options=@http_option)
        if response.code == 200
          items.push(response.body)
        end
      end
      if items.size > 0
        split_line = "\n"+'-'*80 + "\n"
        license_text = items.join(split_line)
      end
    end

    {
      license: license,
      license_url: license_url,
      license_text: license_text
    }
  end
end

end

if __FILE__ == $0
  url = 'https://github.com/aws/aws-sdk-ruby'
  g = API::Github.new(url)
  a = g.get_license_info
  p a[:license_text]

end
