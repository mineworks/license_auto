#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"
require 'json'
require_relative '../lib/cloner'
require_relative '../lib/db'
require_relative '../lib/recorder'
require_relative '../lib/api'
require_relative '../conf/config'


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

    source_url = pack['source_url']
    homepage = pack['homepage']
    packer = {
      :version => pack['version'],
      :source_url => source_url,
      :license_url => pack['license_url'],
      :homepage => homepage,
      :license => pack['license'],
      :license_text => pack['license_text'],
      :status => 30
    }

    github_pattern = /http[s]?:\/\/github\.com/
    if source_url =~ github_pattern
      github_url = source_url
    elsif homepage =~ github_pattern
      github_url = homepage
    else
      github_url = nil
    end

    # TODO: @Micfan
    bitbucket_url = nil
    bitbucket_pattern = /http[s]?:\/\/bitbucket\.org/
    if source_url =~ bitbucket_pattern
      bitbucket_url = source_url
    elsif homepage =~ bitbucket_pattern
      bitbucket_url = homepage
    else
      bitbucket_url = nil
    end

    if github_url != nil
      packer[:source_url] = github_url
      extractor = API::Github.new(github_url, db_ref=packer[:version])
      license_info = extractor.get_license_info(extractor.ref)
      packer = packer.merge(license_info)
      if license_info.values.index(nil)
        packer[:status] = 30
      else
        packer[:status] = 40
      end
    elsif bitbucket_url != nil
      packer[:source_url] = bitbucket_url
      extractor = API::Bitbucket.new(bitbucket_url)
      license_info = extractor.get_license_info
      packer = packer.merge(license_info)
      if license_info.values.index(nil)
        packer[:status] = 30
      else
        packer[:status] = 40
      end
    elsif lang == 'Ruby'
      # TODO:
      #get method for license info
    elsif lang == 'NodeJs'
      # TODO:
      #get method for license info
    else
      $plog.error("!!! Unresolved pack: #{pack}")
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
  puts " [*] Waiting for messages. To exit press CTRL+C"

  begin
    q.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
      puts " [x] Received '#{body}'"
      # My work
      worker(body)
      sleep 1.0
      puts " [x] Done"
      ch.ack(delivery_info.delivery_tag)
    end
  rescue Interrupt => _
    conn.close
  end
end

if __FILE__ == $0
  # body = '{"pack_id":7392}'
  # worker(body)
  main
end
