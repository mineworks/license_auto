require 'json'
require 'httparty'
require_relative '../api/pattern'
require_relative '../../config/config'

module API

class Bitbucket
  attr_reader :repo_url, :protocol, :host, :owner, :repo 
  def initialize(repo_url)
    @repo_url = repo_url

    regex_group = format_url(repo_url)
    @protocol = regex_group[:protocol]
    @host = regex_group[:host]
    @owner = regex_group[:owner]
    @repo = regex_group[:repo]
  end

  def format_url(repo_url)
    repo_url = repo_url.gsub(/\.git/, '')
    repo_url = repo_url.gsub(/\/$/, '')
    patten = API::SOURCE_URL_PATTERN[:bitbucket]
    result = patten.match(repo_url)
  end

  # DOC: https://confluence.atlassian.com/bitbucket/src-resources-296095214.html#srcResources-GETalistofreposource
  # TEST: HTTP GET https://bitbucket.org/api/1.0/repositories/micfan/newsmeme/src/3f62c38/
  def list_contents(path='/')
    reversion = last_commits
    contents = []
    if reversion
      api_url = "https://bitbucket.org/api/1.0/repositories/#{@owner}/#{@repo}/src/#{reversion}#{path}"
      $plog.info("api_url: #{api_url}")
      response = HTTParty.get(api_url)
      if response.code == 200
        contents = JSON.parse(response.licenses)
      else
        # TODO: @Micfan, define custom exceptions
        # raise MyException
        $plog.error("!!! response: #{response}")
      end
    end
    contents
  end

  def filter_license_contents()
    license_contents = {:license => [], :readme => []}
    root_contents = list_contents
    root_contents['files'].each {|c|
      if API::Helper.is_license_file(c['path'])
        license_contents[:license].push(c)
      end
      if API::Helper.is_readme_file(c['path'])
        license_contents[:readme].push(c)
      end
    }
    license_contents
  end

  def get_license_info()
    license = license_url = license_text = nil
    license_contents = filter_license_contents

    license_contents[:license].each {|c|
      revision = c['revision']
      path = c['path']
      api_url = "https://bitbucket.org/api/1.0/repositories/#{@owner}/#{@repo}/raw/#{revision}/#{path}"
      $plog.debug(api_url)
      response = HTTParty.get(api_url)
      if response.code == 200
        license_text = response.licenses
        license_url = api_url

        $plog.info("License file 链接: #{license_url}, #{license_text}")
        license = License_recognition.new.similarity(license_text, STD_LICENSE_DIR)
        if license
          break
        end
      else
        $plog.error("!!! response: #{response}")
      end

    }

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

  def last_commits()
    # TODO: @Micfan, tag
    def get_ref_and_last_commit(branch=nil, tag=nil, mainbranch=true)
      branches_tags = list_branches_tags
      branches = branches_tags['branches']

      mainbranch = last_commit = nil
      branches.each {|br|
        is_mainbranch = br['mainbranch']
        if is_mainbranch
          mainbranch = br['name']
          last_commit = heads = br['heads'][0]
        end
      }
      return mainbranch, last_commit
    end

    mainbranch, last_commits = get_ref_and_last_commit

    # String
    reversion = last_commits
    return last_commits
  end

  # DOC: https://confluence.atlassian.com/bitbucket/repository-resource-1-0-296095202.html#repositoryResource1.0-GETlistofbranches-tags
  def list_branches_tags()
    api_url = "https://bitbucket.org/api/1.0/repositories/#{@owner}/#{@repo}/branches-tags"
    $plog.info("api_url: #{api_url}")
    response = HTTParty.get(api_url)
    last_commit = mainbranch = nil
    branches_tags = nil
    if response.code == 200
      branches_tags = JSON.parse(response.licenses)
    else
      $plog.error("!!! response: #{response}")
    end
    branches_tags
  end

end

end ## API

