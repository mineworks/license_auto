require 'git'
require 'fileutils'
require 'json'
require_relative '../conf/config'
require_relative '../lib/api/pattern'
require_relative '../lib/api/github'

module Cloner

  def self.make_path(repo)
    # todo: If repo is a git@github.com:xxx/yyy
    $plog.debug(repo)
    repo = repo.gsub(/(https:\/\/|http:\/\/|git@)/,'')
    path = "#{AUTO_ROOT}/#{repo}"
  end

  def self.clone_repo(repo, release_id, repo_id, reclone=false)
    path = self.make_path(repo)
    if reclone
      FileUtils::rm_rf(path)
    end
    $plog.debug("Cloning #{repo} into #{path}...")
    # begin
      # Git.configure do |config|
        # If you want to use a custom git binary
        # config.binary_path = '/git/bin/path'

        # If you need to use a custom SSH script
        # Config private SSH key on github.com
      #   config.git_ssh = "#{AUTO_ROOT}/git_ssh_wrapper.sh"
      # end
      if Dir.exists?(path)
        if not $debug
          g = Git.open(path, :log => $plog)
          local_branch = g.branches.local[0].full
          g.pull(remote='origin', branch=local_branch)
        end
      else
        opts = {
          # :recursive => true
          # Only last commit history
          :depth => 1
        }
        local_repo = Git.clone(repo, path, opts)
        path = local_repo.dir.path
      end
      $plog.debug("Cloned #{repo} into #{path}.")

      process_gitmodules(path, release_id, repo_id)

      return path
    # rescue Git::GitExecuteError => e
    #   $plog.error e
    #   return nil
      # return self.clone_repo(repo, reclone=true)
    # end
  end

  # todo: Checkout a branch or tag
  def self.checkout_branch(branch)
    true
  end

  def self.process_gitmodules(clone_path, release_id, parent_repo_id)
    gitmodules = find_gitmodules(clone_path)
$plog.info("Hello, workd: #{gitmodules}")
    gitmodules.each {|url|
      # git@github.com:repo_owner/reop_name
      # TODO: /^(?<username>.+)@/
      ssh_pattern = /^git@/
      git_pattern = /^git:\/\//
      if url =~ ssh_pattern
        url = url.gsub(/:/, '/').gsub(ssh_pattern, 'https://')
      elsif url =~ git_pattern
        url = url.gsub(git_pattern, 'http://')
      end
      $plog.debug("gitmodules url: #{url}")

      g = API::Github.new(url)
      sub_host, sub_repo_owner, sub_repo_name = g.host, g.owner, g.repo
      org_url = "#{sub_host}/#{sub_repo_owner}"

      if api_get_whitelist_orgs(org_url).ntuples > 0
        $plog.debug("submodule in whitelist_orgs: #{url}")

        if api_get_repo_by_url(url).ntuples == 0
          new_added, sub_repo = add_repo(sub_repo_name, url, parent_repo_id=parent_repo_id)
          sub_repo_id = sub_repo['id'].to_i
          $plog.debug("sub_repo_id: #{sub_repo_id}, new_added: #{new_added}")

          case_items = api_query_product_repo(release_id, parent_repo_id)
          $plog.debug("case_items.ntuples: #{case_items.ntuples}")
          if case_items.ntuples > 0
            api_add_product_repo(release_id, parent_repo_id, sub_repo_id)
          end

          if new_added
            mq_publish_repo(release_id, sub_repo_id)
          end
        end
      else
        $plog.debug("submodule not in whitelist_orgs: #{url}")
        pack_name = sub_repo_name
        last_commit = g.last_commits
        pack_version = last_commit ? last_commit['sha'] : nil
        lang = 'github.com'
        source_url = url
        homepage = license = cmt = nil
        status = 10
        add_pack_result = api_add_pack(pack_name, pack_version, lang, homepage, source_url, license, status, cmt)
        pack_id, is_newbie = add_pack_result['pack_id'].to_i, (add_pack_result['is_newbie'] == 't')
        r = api_add_product_repo_pack(parent_repo_id, pack_id, release_id)
        $plog.debug("r: #{r}")
        if is_newbie
          queue_name = 'license_auto.pack'
          $rmq.publish(queue_name, {:pack_id => pack_id}.to_json, check_exist=true)
        end
        $plog.debug("pack_id: #{pack_id}, is_newbie: #{is_newbie}")
      end
    }
  end

  def self.mq_publish_repo(release_id, sub_repo_id)
    message = {
      :release_id => release_id,
      :repo_id => sub_repo_id
    }
    queue_name = 'license_auto.repo'
    $plog.info("submodule is Repo, enqueue MQ.repo, release_id: #{release_id}, sub_repo_id: #{sub_repo_id}")
    $rmq.publish(queue_name, message.to_json)
  end

  def self.find_gitmodules(clone_path)
    gitmodules = []
    filename = '.gitmodules'
    file = "#{clone_path}/#{filename}"
$plog.info("is this file exits? #file}")
    if File.exists?(file)
      contents = File.readlines(file)
$plog.info("content is: #{contents}")
      pattern = /url\s=\s(?<url>.+)(\.git)?$/
      contents.each {|line|
        match_result = pattern.match(line)
$plog.info("match_result: #{match_result}, line: #{line}")
        if match_result
$plog.info("hello url: #{match_result[:url]}")
          gitmodules.push(match_result[:url])
        end
      }

    end
    gitmodules
  end

end

