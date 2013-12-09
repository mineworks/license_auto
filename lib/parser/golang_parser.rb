#!/usr/bin/env ruby
# coding: utf-8

require 'json'
require 'open3'
require 'set'
require_relative '../../lib/cloner'
require_relative '../../enums'
require_relative '../../config/config'
require_relative '../recorder'


class GolangParser

  def self.start(repo_filepath)
    pack__name_uris = {}

    pack_names = self.find_pack_names(repo_filepath)
    pack_names.each {|pack_name|
      pack_uri = ''
      begin
        pack_uri = self.golang_extpack_to_repo_uri(pack_name)
      rescue Exception => e
        # todo: save bad golang package into DB
        pack_uri = e
      end
      name = pack_uri.gsub(/http(s)?:\/\//,'')
      if pack_uri != nil
        pack__name_uris.store(name, pack_uri)
      end
    }
    $plog.debug("GolangParser: pack__name_uris: #{pack__name_uris}")
    return pack__name_uris
  end

  # return: pack_names {Set} eg. { 'github.com/some_golang_author/hist_package', ... }
  def self.find_pack_names(repo_filepath)
    pack_names = Set.new

    $plog.debug("repo_filepath: #{repo_filepath}")

    Dir.chdir(repo_filepath) do
      cmd = 'go list -json ./...'
      Open3.popen3(cmd) {|i,o,e,t|
        out = o.readlines
        error = e.readlines
        if error.length > 0 and error[0] != "warning: \"./...\" matched no packages\n"
          raise "cmd error: #{error}"
        elsif out.length > 0
          out2 = out.join('').gsub(/}\n{/, "}\n\n{").split(/\n\n/)
          out2.each {|s|
            j = JSON::parse(s)
            # $plog.info("json: #{j}")
            imports = []
            section_keys = ['Deps', 'Imports', 'TestImports', 'XTestImports']
            section_keys.each {|s|
              if j[s]
                imports += j[s]
              end
            }

            if imports.size == 0
              next
            else
              imports.each {|d|
                unless GOLANG_STD_PACKAGES.include?(d)
                  unless d.index('.').nil?
                    pack_names.add(d)
                  end
                end
              }
            end
          }
        else
          $plog.error "!!!Opps'"
        end
        exit_status = t.value
        pack_names
        p pack_names
      }
    end
    return pack_names
  end

  def self.golang_extpack_to_repo_uri(extpack)
    pack_repo = nil
    # todo: Case lower convert
    uri = no_protocol_uri = extpack.split('/')
    host, owner, pack_name = uri[0], uri[1], uri[2]
    # todo: In china, you have to setup a proxy for Google Code
    # sites = {
    #     #  'code.google.com',
    #   https: ['github.com', 'bitbucket.org', 'git.oschina.net'],
    #   http: [],
    #   git: []
    # }
    if extpack.index('.')
      pack_repo = "https://#{host}/#{owner}/#{pack_name}"
    else
      $plog.error("不是外部Golang包: #{extpack}")
    end
    return pack_repo
  end
end
