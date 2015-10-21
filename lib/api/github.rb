# encoding: utf-8
require 'httparty'
require 'json'
require_relative '../../extractor_ruby/License_recognition'
require_relative '../misc'
require_relative '../api/pattern'
require_relative './helper'

module API

class Github
  attr_reader :ref

  def initialize(repo_url, db_ref=nil)
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

    @ref = _match_a_ref(db_ref)
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

  def format_url(repo_url)
    repo_url = repo_url.gsub(/\.git$/, '')
    patten = API::SOURCE_URL_PATTERN[:github]
    result = patten.match(repo_url)
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

  def get_license_info()
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
        if File.extname(c['name']) == '.rdoc'
          regular_start = /^==[ ]*(copying|license){1}:*/i
          regular_end   = /^==/
        elsif File.extname(c['name']) == '.md'
          regular_start = /^##[ ]*(copying|license){1}:*/i
          regular_end   = /^##/
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
            if line =~ regular_start
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

    {
      license: license,
      license_url: license_url,
      license_text: license_text
    }
  end
end

end ### API

if __FILE__ == $0
  url = 'https://github.com/geemus/netrc'
  g = API::Github.new(url, '0.7')
  br = g.get_default_branch
  p br
end
