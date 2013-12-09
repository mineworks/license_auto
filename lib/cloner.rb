require 'git'
require 'fileutils'
require_relative '../conf/config'


# todo: add svn clone
module Cloner

  def self.make_path(repo)
    # todo: If repo is a git@github.com:xxx/yyy
    $plog.debug(repo)
    repo = repo.gsub(/(https:\/\/|http:\/\/|git@)/,'')
    path = "#{AUTO_ROOT}/#{repo}"
  end

  def self.clone_repo(repo, reclone=false)
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
          :recursive => true
        }
        local_repo = Git.clone(repo, path, opts)
        clone_path = local_repo.dir.path
        return clone_path
      end
      $plog.debug("Cloned #{repo} into #{path}.")
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

end

