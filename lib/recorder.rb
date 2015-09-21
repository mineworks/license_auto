# encoding: utf-8
require 'csv'
require 'json'
require_relative '../conf/config'
require_relative './api'

class PacksSaver
  def initialize(repo_id, packs, lang, release_id)
    @release_id = release_id
    @repo_id = repo_id
    @packs = packs
    @lang = lang
  end

  def save()
    if @lang == 'Golang'
      save_golang
    elsif @lang == 'Ruby'
      save_ruby
    end
  end
  def save_ruby
    # 格式化DB自定义license格式
    def license_name_format(origin_license)
      if origin_license.nil?
        return nil
      end
      empty_pattern = /---\s\[\]\n/
      license = origin_license.gsub(empty_pattern, '').gsub(/---\s\n[\.]+\n/, '').gsub(/---\n-\s/, '').gsub(/\n/, '').gsub(/['"\s]+$/, '').gsub(/^['"\s]+/, '')
      if license.empty?
        return nil
      else
        return license
      end
    end

    @packs.each {|pack|
      begin
        $plog.debug(pack)
        pack_name, pack_version, status = pack[:pack_name], pack[:pack_version], pack[:status]
        homepage, source_url = pack[:homepage], pack[:source_url]
        license, cmt = pack[:license], pack[:cmt]
        license = license_name_format(license)

        pg_result = api_add_pack(pack_name, pack_version, 'Ruby', homepage, source_url, license, status, cmt)
        enqueue_result(pg_result)
      rescue Exception => _
        $plog.error(_)
      end
    }
  end

  # 处理api_add_pack()返回的结果
  def enqueue_result(pg_result)
    begin
      if pg_result != nil
        pack_id = pg_result['pack_id'].to_i
        is_newbie = pg_result['is_newbie'] == 't'
        api_add_product_repo_pack(@repo_id, pack_id, @release_id)

        if is_newbie
          queue_name = 'license_auto.pack'
          $rmq.publish(queue_name, {:pack_id => pack_id}.to_json, check_exist=true)
        end
        $plog.debug("pack_id: #{pack_id}, is_newbie: #{is_newbie}")
      else
        $plog.error("#{pack_url} insert failed!")
      end
    rescue Exception => _
      $plog.error(_)
    end
  end

  def save_golang()
    @packs.each { |pack_name, pack_url|
      begin
        pack_version = 'unknown'

        if pack_url.index('github.com')
          g = API::Github.new(pack_url)
          last = g.last_commits
          pack_version = last['sha'] unless last.nil?
        end
        if pack_url.index('bitbucket.org')
          b = API::Bitbucket.new(pack_url)
          last_commit = b.last_commits
          pack_version = last_commit unless last_commit.nil?
        end

        $plog.debug("#{pack_version}, #{pack_url}")
        homepage = license = nil
        if pack_url =~ /github\.com/ or pack_url =~ /bitbucket\.org/
          status = 10
          cmt = nil
        else
          status = 30
          cmt = 'Not github or bitbucket'
        end
        pg_result = api_add_pack(pack_name.split('/').last, pack_version, 'Golang', homepage, pack_url, license, status, cmt)
        enqueue_result(pg_result)
      rescue Exception => _
        $plog.error(_)
      end
    }
  end

end

class PackUpdate
  def initialize(pack_id, pack)
    @pack_id = pack_id
    @pack = pack
    #@status = 10
  end

  def update()
    
    #if @pack['version'] == nil or @pack['version'] == ''
      #@pack['version'] = 'unknown'
      #@status = 30
    #else
      #@status = 40
    #end
    if check_std_license(@pack[:license])
      @pack[:unclear_license] = nil
      @pack[:status] = 40
    else
      @pack[:unclear_license] = @pack[:license]
      @pack[:license] = 'UNKNOWN'
      @pack[:status] = 30
    end
    #if @pack['homepage'] == nil and @pack['source_url'] == nil and @pack['license_url'] == nil
      #@status = 30
    #end
    
    #@pack['status'] = @status
    
    flag = api_update_pack_info(@pack_id,@pack)

    return flag
        
  end

  def check_std_license(license)
    std_license_list = api_get_std_license_name()
    num = 0
    flag = false
    while num < std_license_list.ntuples() do
      if(license == std_license_list[num]['name'])
        flag = true
        break
      end
      num = num + 1
      next
    end
    return flag
  end

end
