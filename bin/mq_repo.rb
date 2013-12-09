#!/usr/bin/env ruby
# encoding: utf-8

require 'openssl'

require_relative '../lib/parser/golang_parser'
require_relative '../lib/parser/erlang_parser'
require_relative '../lib/parser/manifest_parser'
require_relative '../lib/parser/npm_parser'
require_relative '../lib/parser/gradle_parser'
require_relative '../lib/parser/maven_parser'
require_relative '../lib/cloner'
require_relative '../lib/db'
require_relative '../lib/recorder'


def worker(body)
  begin
    case_item = JSON.parse(body)

    repo_id = case_item['repo_id'].to_i
    if repo_id == 404
      return
    end
    release_id = case_item['release_id'].to_i
    repo_url = api_get_repo_source_url(repo_id)

    api_clear_relations(release_id, repo_id)

    clone_path = Cloner::clone_repo(repo_url, release_id, repo_id)

    if clone_path == nil
      cmt = "!!! clone_path is empty. repo_url: #{repo_url}"
      $plog.fatal(cmt)
      # TODO: repo -> case_id
      api_setup_case_status(repo_id, 20, cmt)
      return
    end

    # TODO: @Frank, refactor to use config file and load at runtime
    packs = GolangParser.start(clone_path)
    saver = PacksSaver.new(repo_id, packs, 'Golang', release_id)
    saver.save

    ruby_packs = ExtractRuby::RubyExtractotr.new(clone_path).start
    saved = PacksSaver.new(repo_id, ruby_packs, 'Ruby', release_id).save

    manifest_packs = ManifestParser.new(clone_path, repo_id).start
    saved = PacksSaver.new(repo_id, manifest_packs, 'manifest.yml', release_id).save

    npm_packs = NpmParser.new(clone_path).start
    saved = PacksSaver.new(repo_id, npm_packs, 'NodeJs', release_id).save

    gradle_packs = GradleParser.new(clone_path).start
    saved = PacksSaver.new(repo_id, gradle_packs, 'Gradle', release_id).save

    pom_packs = MavenParser.new(clone_path).start
    saved = PacksSaver.new(repo_id, pom_packs, 'Gradle', release_id).save

    packs = ErlangParser.new(clone_path).start
    saver = PacksSaver.new(repo_id, packs, 'Erlang', release_id)
    saver.save

  rescue Git::GitExecuteError => e
    $plog.fatal(e)
    api_setup_case_status(repo_id, 21, e.to_s)
  # TODO: ignore
  rescue OpenSSL::SSL::SSLError => e
    $plog.fatal(e)
    api_setup_case_status(repo_id, 22, e.to_s)
  rescue Exception => _
    $plog.error(_)
  end
end

def main()
  conn = Bunny.new
  conn.start

  ch   = conn.create_channel
  q    = ch.queue("license_auto.repo", :durable => true)

  ch.prefetch(1)
  $plog.info(" [*] MQ-repo: Waiting for messages. To exit press CTRL+C")

  begin
    q.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
      $plog.info(" [x] MQ-repo: Received '#{body}'")
      worker(body)
      sleep 1.0
      $plog.info(" [x] MQ-repo: Done")
      ch.ack(delivery_info.delivery_tag)
    end
  rescue Interrupt => _
    conn.close
  end
end

if __FILE__ == $0
  # repo_id = 384
  # release_id = 10
  # body = "{\"repo_id\": #{repo_id}, \"release_id\": #{release_id}}"
  # worker(body)
  main
end

