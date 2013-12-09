#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"
require 'json'
require_relative '../lib/cloner'
require_relative '../lib/db'
require_relative '../lib/recorder'
require_relative '../lib/api'
require_relative '../conf/config'

def fetch_license_info_by_source(packer, status=nil)
    # TODO: @Micfan, simple it
    source_url = packer[:source_url]
    homepage = packer[:homepage]
    github_pattern = /http[s]?:\/\/github\.com/
    if source_url =~ github_pattern
      github_url = source_url
    elsif homepage =~ github_pattern
      github_url = homepage
    else
      github_url = nil
    end

    bitbucket_url = nil
    bitbucket_pattern = /http[s]?:\/\/bitbucket\.org/
    if source_url =~ bitbucket_pattern
      bitbucket_url = source_url
    elsif homepage =~ bitbucket_pattern
      bitbucket_url = homepage
    else
      bitbucket_url = nil
    end

    license_info = {:license => nil, :license_text => nil, :license_url => nil}
    if github_url != nil
      packer[:source_url] = github_url
      extractor = API::Github.new(github_url, db_ref=packer[:version])
      license_info = extractor.get_license_info(extractor.ref)
      packer = packer.merge(license_info)
    elsif bitbucket_url != nil
      packer[:source_url] = bitbucket_url
      extractor = API::Bitbucket.new(bitbucket_url)
      license_info = extractor.get_license_info
      packer = packer.merge(license_info)
    end

    if status
      packer[:status] = status
    elsif license_info.values.index(nil)
      packer[:status] = 30
    else
      packer[:status] = 40
    end

    # TODO: check_std_license in Ruby program, do not in db process

  return packer
end

def worker(body)
  begin
    pack_item = JSON.parse(body)
    pack_id = pack_item['pack_id']
    pack = api_get_pack_by_id(pack_id)
    if pack.nil?
      status = 20
      cmt = "Package not found, pack_id: #{pack_id}"
      api_setup_pack_status(pack_id, status, cmt)
      $plog.fatal(cmt)
      return
    else
      _status = pack['status'].to_i
      if _status >= 30
        cmt = "This package(pack_id=#{pack_id}, status=#{_status}) have no permission to self run"
        $plog.info(cmt)
        return
      end
    end

    $plog.debug("pack: #{pack}")

    lang = pack['lang']

    packer = {
      :version => pack['version'],
      :source_url => pack['source_url'],
      :license_url => pack['license_url'],
      :homepage => pack['homepage'],
      :license => pack['license'],
      :license_text => pack['license_text'],
      :status => 30
    }
    packer = fetch_license_info_by_source(packer)
    if packer[:status] < 40 and packer[:source_url] == nil
      if lang == 'Java'
        # TODO: 3 website
      elsif lang == 'NodeJs'
        # TODO:
      else
        $plog.info("packer: #{packer}")
        if packer[:source_url] == nil and packer[:homepage] != nil
          spider_source_url = API::Spider.new(packer[:homepage], pack['name']).find_source_url
          $plog.fatal("spider_source_url: #{spider_source_url}")
          if spider_source_url
            packer[:source_url] = spider_source_url
            packer = fetch_license_info_by_source(packer, status=31)
          end
        end
        $plog.error("!!! Unresolved pack: #{pack}")
      end
    end
    #test
    #packer = Hash.new()
    #packer["version"] = '1.1.0'
    #packer["homepage"] = nil
    #packer["source_url"] = nil
    #packer["license_url"] = nil
    #packer["license"] = nil
    #packer["license_text"] = nil
    #test

    updater = PackUpdate.new(pack_id, packer)
    flag = updater.update()
    if flag
      $plog.info("update success: pack_id: #{pack_id}, packer: #{packer}")
    else
      $plog.info("!!! update failed: pack_id: #{pack_id}, packer: #{packer}")
    end
  rescue Git::GitExecuteError => e
    $plog.fatal(e)
    api_setup_pack_status(pack_id, 21, e.to_s)
  rescue OpenSSL::SSL::SSLError => e
    $plog.fatal(e)
    api_setup_pack_status(pack_id, 22, e.to_s)
  rescue Exception => e
    api_setup_pack_status(pack_id, 20, e.to_s)
    $plog.fatal(e)
  end
  
end

def main()
  conn = Bunny.new
  conn.start

  ch   = conn.create_channel
  q    = ch.queue("license_auto.pack", :durable => true)

  ch.prefetch(1)
  puts " [*] MQ-pack: Waiting for messages. To exit press CTRL+C"

  begin
    q.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
      puts " [x] MQ-pack:  Received '#{body}'"
      # My work
      worker(body)
      sleep 1.0
      puts " [x] MQ-pack: Done"
      ch.ack(delivery_info.delivery_tag)
    end
  rescue Interrupt => _
    conn.close
  end
end

if __FILE__ == $0
  # sql= "select distinct on (name)* from pack
  #   where source_url like '%github%'"
  # packs = $conn.exec(sql)
  #
  # packs.each {|p|
  #   #$plog.debug(p)
  #   pack_id = p['id']
  #   body = '{"pack_id":' + "#{pack_id}}"
  #   worker(body)
  # }

  pack_id = 193
  body = '{"pack_id":' + "#{pack_id}}"
  worker(body)

  #main
end
