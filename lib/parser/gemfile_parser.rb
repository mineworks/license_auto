require 'thread/pool'
require 'bundler'

require_relative './Obtain_path'
require_relative './Ruby_extractor'
require_relative './utils'
require_relative '../config/config'
require_relative '../lib/api/pattern'
#require 'License_recognition'

include Ruby_extractor



module ExtractRuby
  class Ex
    include Ruby_extractor,Utils
  end

  class RubyExtractotr < Ex

    # attr_reader :two_dependencies
    attr_reader :package_list

    def initialize(repo_path)
      @repo_path = repo_path

      @package_list       = [] # [name, version, status] package list , not exist "\n"
      @rubygems_not_found = 30 # rubygemsDB not found
      @status_init = 10
      # gem server or git uri
      @status_private_source = 33
    end

    # https://gist.github.com/flavio/1722530
    # DOC: https://github.com/bundler/bundler/blob/master/lib/bundler/lockfile_parser.rb
    # description : use bundler extract ruby package from gemfile.lcok
    # repo_path   : local repo path , type : String
    # st_true     : Correct extraction 10
    # s.source.options['tag'], ['revision']
    def get_first_level_specs()
      all_specs = []
      lockfiles = Obtain_path.new(@repo_path, "gem", ".lock").get_data
      if lockfiles.size == 0
        $plog.info('Gemfile.lock files not found, Ruby packages not found')
        return all_specs
      end

      lockfiles.each do |pathname|
        $plog.debug("Gemfile.lock file pathname: #{pathname}")
        lockfile_parser = Bundler::LockfileParser.new(Bundler.read_file(pathname))
        lockfile_parser.specs.each do |s|
          all_specs.push(s)
          # The 2nd level dependencies
          # s.dependencies.each{|rows|
          #   rows.requirement.requirements.each{|row|
          #     tmp.concat [[row[0], row[1].version]]
          #   }
          # }
        end
      end
      all_specs
    end

    def start
      all_packs = []
      require_relative '../lib/api/gem_data'
      require_relative '../lib/api'
      local_gemdb = API::GemData.new
      rubygems_org = 'https://rubygems.org'
      rubygems_org_domain = 'rubygems.org'

      first_level_specs = get_first_level_specs
      first_level_specs.each {|s|
        # $plog.debug("git_uri: #{s.source.options['uri']}, remotes: #{s.source.options['remotes']}")
        # gem_server_remotes.join(',').gsub(/http[s]?:\/\//, '')
        pack = nil
        pack_name = s.name
        pack_version = s.version.to_s

        if s.source.class == Bundler::Source::Git
          source_url = s.source.options['uri']
          _status = @status_init
          _lang = source_url
          _cmt = nil

          if source_url =~ API::SOURCE_URL_PATTERN[:github]
            g = API::Github.new(source_url)
            source_url = g.repo_url
            _lang = 'https://github.com'
            if g.list_contents('').size == 0
              _status = @status_private_source
              _cmt = 'Private git uri, source code not found'
            end
          end
          pack = {
            pack_name: pack_name,
            pack_version: pack_version,
            homepage: nil,
            source_url: source_url,
            license: nil,
            status: _status,
            language: _lang,
            # This cmt require local rubygems.org database always up-to-date
            cmt: _cmt
          }
        elsif s.source.class == Bundler::Source::Rubygems
          gem_server_remotes = s.source.options['remotes']

          formatted_remotes = gem_server_remotes.collect {|r|
            r.gsub(/\/$/, '').gsub(/http:\/\/rubygems\.org/, rubygems_org)
          }
          # TODO: get Gemfile source section
          db_pack = local_gemdb.get_gem(pack_name, pack_version)
          if formatted_remotes.index(rubygems_org) and db_pack
            pack = db_pack.merge({
                                    :status => 10,
                                    :language => rubygems_org_domain,
                                    :cmt => nil
                                  })
          else
            formatted_remotes.delete(rubygems_org)
            pack = {
              pack_name: pack_name,
              pack_version: pack_version,
              homepage: nil,
              source_url: nil,
              license: 'UNKNOWN',
              status: @status_private_source,
              language: formatted_remotes.join(''),
              # This cmt require local rubygems.org database always up-to-date
              cmt: 'Private gem server or source code not found'
            }
          end
        end
        all_packs.push(pack)
      }
      all_packs
    end

    def select_rubygems_db
      # FIXME: db connection
      require_relative '../lib/api/gem_data'
      rubygems_result = []
      ruby_gems = API::GemData.new
      @package_list.each do |row|
        pack_hash = {
            :pack_name => nil,
            :pack_version => nil,
            :homepage => nil,
            :source_url => nil,
            :license => nil,
            :status => 10,
            :cmt => nil,
            :language => nil
        }
        if row['uri'] != nil
          pack_hash[:language]     = row['uri']
          pack_hash[:pack_name]    = row['name']
          pack_hash[:pack_version] = row['version']
          pack_hash[:source_url]   = row['uri']
          rubygems_result << pack_hash
          next
        elsif row['remotes'] != nil
          pack_hash[:language] = row['remotes']
        end
        if 10 == row['st']
          result = ruby_gems.get_gemdata(row['name'],row['version'])
          if result != nil
            pack_hash[:pack_name]    = result[:name]
            pack_hash[:pack_version] = result[:version]
            pack_hash[:homepage]     = result[:homepage]
            pack_hash[:source_url]   = result[:source_url]
            pack_hash[:license]      = result[:license]
            pack_hash[:status]       = row['st']
          elsif nil == result
            pack_hash[:pack_name]    = row['name']
            if "" == row['version']
              pack_hash[:pack_version] = nil
            else
              pack_hash[:pack_version] = row['version']
            end
            pack_hash[:status]       = @rubygems_not_found
          end
        end

        rubygems_result << pack_hash
      end

      return rubygems_result
    end

  end
end

if __FILE__ == $0

end























