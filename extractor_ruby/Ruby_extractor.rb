require "weakref"
require 'httparty'
require 'json'
require_relative './License_recognition'
# require_relative '../conf/config'

module Ruby_extractor

  # filename    : file name include path ,  type : String
  # data        : file data ,              type : Array
  def write_file(filename, data, mode = 'w', n = 0)
    file = File.new(filename, mode)
    data.each do | content |
      file.write(content) if 0 == n
      file.write(content + "\n") if 1 == n
    end
    file.close
    file = WeakRef.new(file)
    GC.start
  end

  # description : Get license to github
  # github_url  : github URL
  def getLicenseFromGithub(github_url)

    licenseName      = ""
    licenseUrl       = ""
    licenseText      = ""

    unless github_url =~ /https/
      github_url.gsub!(/http/,'https')
    end
    getHtmlWithAnemone(github_url) do |page|
      if page.html?
        #page.doc.xpath("//table[@class="files"]/tbody/tr/td[1]/span/a").each do | link |
        page.doc.css("table.files td.content span a").each do | title |
          #p title.css('/@title').map(&:value)
          if  title.css('/@title').map(&:value).to_s =~ /(copying|license){1}/i
            licenseName   =  title.css('/@title').map(&:value)[0]
            licenseName ||= ""
            #p "licenseName  : #{licenseName }"

          end
        end
        unless licenseName.empty?
          licenseUrl   = page.doc.css("a[title='#{licenseName}']").css('/@href').map(&:value)[0]
          licenseUrl ||= ""
          #p licenseUrl
          #break
        end
      else
        #p "Not get license info , not a html page ?"
      end
      page = WeakRef.new(page)
      #puts "page memory size: #{ObjectSpace.memsize_of page}"
    end

    if !licenseUrl.empty?
      licenseUrl = "https://github.com" + licenseUrl
      p "licenseUrl : #{licenseUrl}"
      license    = nil
      getHtmlWithAnemone(licenseUrl) do |page|
        if page.html?
          rawLicenseUrl = page.doc.css('a#raw-url').css('/@href').map(&:value)[0]
          rawLicenseUrl ||= ""
          if !rawLicenseUrl.empty?
            rawLicenseUrl = "https://github.com" + rawLicenseUrl
            p rawLicenseUrl
            licenseRaw    = getHtmlWithAnemone(rawLicenseUrl) { |page|  page.doc.css('a').css('/@href').map(&:value)[0]  }
            #"<html><body>You are being <a href=\"https://raw.githubusercontent.com/sporkmonger/addressable/master/LICENSE.txt\">redirected</a>.</body></html>"
            licenseRaw ||= ""
            licenseText   = getHtmlWithAnemone(licenseRaw) { |page| page.body  } unless licenseRaw.empty?
            licenseText ||= ""

            License_recognition.new.similarity(licenseText,"./Package_license")
            license       = ex_word(licenseText.gsub(/\\n/,' ').gsub(/\\t/,' ')) unless licenseText.empty?
            #licenseText = WeakRef.new(licenseText)
            #GC.start
            #p "License : #{license}"
            #p "----------------------------"
            if license =="ERROR"
              license = nil
            end
          end
        end
      end #end block
      # license || "" : if license = nil  then license = ""
      return licenseUrl,license || ""
    end
    return nil
  end

  # description : from rubygems.org get package info
  # reference   : http://guides.rubygems.org/rubygems-org-api/
  #               http://www.rubydoc.info/gems/httparty/0.13.5
  #
  def rubygems(gem_pair)
    #gem_name, version = gem_pair.split(',')
    gem_name = gem_pair[0]
    version  = gem_pair[1]
    download_url = ''
    license      = ''
    api_url = "https://rubygems.org/api/v1/gems/#{gem_name}.json"
    response = HTTParty.get(api_url)
    if 200 == response.code
      h = JSON::parse(response.body)

      # h['homepage_uri']  if there is null  return nil
      github_pattern = /http(s)?:\/\/github.com\//
      if h['homepage_uri'] != nil  and h['homepage_uri'] =~ github_pattern
          download_url = h['homepage_uri']
      end
      if h['source_code_uri'] != nil and h['source_code_uri'] =~ github_pattern
          download_url = h['source_code_uri']
      end
      if download_url == ''
        # rubygems.org url
        download_url = h['project_uri']
      end
      if version == nil or version == ''
        version = h['version']
      end
      if download_url =~ github_pattern
        p download_url
        result = getLicenseFromGithub(download_url)
      end

      # return ''

      if !h['licenses'].empty?
        h['licenses'].each do |element|
          if h['licenses'][0] != element
            license += '#'
          end
          license += element
        end
      else
        if download_url =~ github_pattern
          result = getLicenseFromGithub(download_url)
          p "result : #{result}"
          if nil != result
            license = result[1]
          else
            p "result == nil"
            # if h['licenses'] == nil then website display 'N/A'
            license = 'N/A'
          end
        end
      end

      p "#{gem_name},#{version},#{license},,,#{download_url},\n"
      return "#{gem_name},#{version},#{license},,,#{download_url},\n"

    elsif 404 == response.code
      # todo:
      p "#{gem_name},#{version},#{license},,,rubygems.org page not found,\n"
      return "#{gem_name},#{version},#{license},,,rubygems.org page not found,\n"
    else
      # todo:
      p "#{gem_name},#{version},#{license},,,unknown error,\n"
      return "#{gem_name},#{version},#{license},,,unknown error,\n"
    end

  end # def rubygems

  # description : output path
  # log path (1): ./output/#{repo_name}/log/
  # process package: ./ouput/#{repo_name}/
  # finish result  : ./output/#{repo_name}/
  # result package : ./ouput/#{repo_name}/
  # mode        : 1,log path   2 finsh result path
  def out_path(repo_name,mode)
    if !File.exist?("./output")
      Dir.mkdir("./output")
    end
    if(!File.exist?("./output/#{repo_name}"))
      Dir.mkdir("./output/#{repo_name}")
    end
    if mode == 1
      if(!File.exist?("./output/#{repo_name}/log"))
        Dir.mkdir("./output/#{repo_name}/log")
      end
      return "./output/#{repo_name}/log"
    end
    if mode == 2
      return "./output/#{repo_name}"
    end
  end # def out_path

  def rule(string)
    exact_name          = ''
    exact_version       = ''
    index_version_begin = 0
    index_version_end   = 0
    flag                = "open"

    stack1 = Array.new

    stack2 = Array.new

    # no return nil
    result = string =~ /[ ][(]/

    if string.size() == 0
      exact_name = "ERROR"
      #only package name
    elsif (result == nil)
      for i in (0 ... string.size())  do
        if (string[i] =~ /[0-9a-zA-Z_-]/)
          stack1.push(string[i])
        else
          exact_name = "ERROR"
          break
        end
      end
    else
      for i in (0 ... string.size()) do
        if (string[i] == ' ' and string[i+1] == '(')
          break
        end
      end
      # name
      for j in (0 ... i)  do #string[i] == ' '
        if (string[j] =~ /[0-9a-zA-Z_-]/)
          stack1.push(string[j])
        else
          exact_name = "ERROR"
          break
        end
      end

      if (string =~ /[^!][=]/ )
        for j in (i ...string.size()) do
          if (string[j-1] != '!' and string[j] == '=' and string[j+1] == ' ')
            index_version_begin = j+2
            index_version_end   = j+2
            for k in (j+2 ... string.size()) do
              if (string[k] == ',' or string[k] == ')')
                index_version_end = k
                break
              end
            end
            break
          elsif ((string[j] =~ /[0-9a-zA-Z.><~!=(, ]/)  == nil )
            exact_name = "ERROR"
            break
          end
        end
      else
        for j in (i ... string.size()) do
          if (string[j] == '=')
            flag = "close"
          elsif (string[j] == ',')
            flag = "open"
          end
          if (flag == "open" and (string[j] == ' ' or string[j] == '(') and string[j+1] =~ /[0-9a-zA-Z.]/ )
            index_version_begin = j+1
            index_version_end   = j+1
            for k in (j+1 ... string.size()) do
              if (string[k] == ',' or string[k] == ')')
                index_version_end = k
                break
              end
            end
            break
          elsif ((string[j] =~ /[0-9a-zA-Z.><~!=(, ]/)  == nil )
            exact_name = "ERROR"
            break
          end
        end
      end
      # version
      for k in (index_version_begin ... index_version_end) do
        if (string[k] =~ /[0-9a-zA-Z.]/)
          stack2.push(string[k])
        else
          exact_name = "ERROR"
          break
        end
      end
    end

    # return package name and package version
    if (exact_name == "ERROR")
      return exact_name
    else
      #return stack1.join() + "," + stack2.join()
      return stack1.join(), stack2.join()
    end
  end # end rule

  # description : ruby pacakge extract from gemfile.lock file
  # input       : gemfile.lock data.                      type : Array
  # container   : succeed extract ruby name,version list. type: Array
  ## gemfile     : gemfile.lock content  delete "\n" and " "
  # start_1 ..3 : begin flag
  # finish_1 ..3: finish flag
  # return      : extract failure list.                   type Array
  def extract_ruby(input, container, st_true, st_error, start_1 = "GEM", start_2 = "rubygem", start_3 = "specs", finish_1 = "", finish_2 = "PLATFORMS",finish_3 = "ruby")
    if input.size() == 0
      return []
    end

    index_start = 0
    index_end   = 0
    line        = ''
    line1       = ''
    line2       = ''
    flag        = 'close'

    lines       = Array.new()
    out_lines   = Array.new() # return valid
    succeed     = Array.new()
    failure     = Array.new()
    #input.each_line { |line| lines.push(line) }

    lines = input

    for i in (0...lines.size()-2) do
      if lines[i] == "\n" or lines[i] == ""
        line = ""
      else
        line = lines[i].strip()
      end
      if (lines[i+1] == "\n" or lines[i+1] == "")
        line1 = ""
      else
        line1 = lines[i+1].strip()
      end
      if (lines[i+2] == "\n" or lines[i+2] == "")
        line2 = ""
      else
        line2 = lines[i+2].strip()
      end
      # puts line
      if (flag == "close" and line.include? start_1 and line1.include? start_2)
        for j in (i+2 ... lines.size()-2) do
          line = lines[j].strip()
          if line.include? start_3
            flag 				= "open"
            index_start = j+1
            index_end   = i+1
          end
        end
      end
      if (flag == "open" and line.include? finish_1 and line1.include? finish_2 and line2.include? finish_3)
        # puts "OK1"
        index_end = i
        break
      end
    end

    # FIXME: '{"repo_id":38}' returned [], GIT section count or not? @Kim
    # $plog.info("### #{index_end} : #{index_end}")
    if index_end > index_start
      for j in (index_start ... index_end) do
        if (lines[j] == "\n" or lines[j] == "")
          line = "ERROR"
        else
          line = rule(lines[j].strip())
        end

        if (line == "ERROR")
          # strip : Remove head and tail all white-space characters.Blank characters are "\t\r\n\f\v".
          #failure.push(lines[j].strip,'',st_error)
          failure << [lines[j].strip(), '', st_error]
        else
          #succeed.push(line + ',' + lines[j].strip())
          #succeed.push(line,st_true)
          succeed << [line[0], line[1], st_true]
        end
      end
      container.concat(succeed)
      succeed.clear
      return failure
    else
      return []
    end
  end ## extract_ruby



end # module Ruby_extractor