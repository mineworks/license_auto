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
    elsif @lang == 'manifest.yml' or @lang == 'NodeJs' or @lang == 'Erlang'
      save_manifest
    elsif @lang == 'Gradle'
      save_gradle
    end
  end

  def save_gradle
    @packs.each {|pack|
      begin
        $plog.debug(pack)
        pack_name, pack_version, status = [pack[:group], pack[:name]].join(':'), pack[:version], 10
        homepage, source_url = nil, pack['uri']
        license, cmt = nil, nil

        pg_result = api_add_pack(pack_name, pack_version, @lang, homepage, source_url, license, status, cmt)
        enqueue_result(pg_result)
      rescue Exception => _
        $plog.error(_)
      end
    }
  end

  def save_manifest
    @packs.each {|pack|
      begin
        $plog.debug(pack)
        pack_name, pack_version, status = pack['name'], pack['version'], 10
        homepage, source_url = nil, pack['uri']
        license, cmt = nil, nil

        pg_result = api_add_pack(pack_name, pack_version, @lang, homepage, source_url, license, status, cmt)
        enqueue_result(pg_result)
      rescue Exception => _
        $plog.error(_)
      end
    }
  end

  def save_ruby
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
        pack[:license] = license_name_format(pack[:license])
        # $plog.debug(pack)
        pack_name, pack_version, status = pack[:pack_name], pack[:pack_version], pack[:status]
        homepage, source_url = pack[:homepage], pack[:source_url]
        # lang is a website in act
        license, cmt, lang = pack[:license], pack[:cmt], pack[:language]

        pg_result = api_add_pack(pack_name, pack_version, lang, homepage, source_url, license, status, cmt)
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
        $plog.debug("save_golange: #{pack_url}")

        pack_version = 'unknown'
        homepage = nil
        source_url = nil
        status = 10
        cmt = nil

        remote = API::RemoteSourceVCS.new(pack_url)

        if remote.vcs == nil
          status = 30
          cmt = 'Unknown repo site'
          pack_name = pack_name.split('/').last
        else
          pack_name = remote.vcs.repo
          source_url = remote.vcs.repo_url
          homepage = remote.get_homepage
          last_commit = remote.vcs.last_commits
          if last_commit
            pack_version = last_commit['sha']
          end
        end
        # $plog.debug("#{pack_version}, #{pack_url}")
        license = nil
        pg_result = api_add_pack(pack_name, pack_version, 'Golang', homepage, source_url, license, status, cmt)
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
  end

  def update()
    ok = api_update_pack_info(@pack_id, @pack)
  end

  def self.judge_pack_status(packer)
    # TODO: @Micfan test it
    if is_std_license(packer[:license]) and ( packer[:license_url] or packer[:license_text])
      packer[:unclear_license] = nil
      packer[:status] = 40
    else
      packer[:unclear_license] = packer[:license]
      packer[:license] = nil
      packer[:status] = 30
    end
    return packer
  end

  def self.is_std_license(license)
    where = "where name = '#{license}'"
    std_licenses = api_get_std_license_name(where)
    return std_licenses.ntuples == 1
  end

end

if __FILE__ == $0
  p PackUpdate.is_std_license('MIT')
end
