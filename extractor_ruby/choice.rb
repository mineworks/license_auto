require 'thread/pool'
require 'bundler'

require_relative './Obtain_path'
require_relative './Ruby_extractor'
require_relative './Read_local_data'
require_relative './utils'
#require 'License_recognition'

include Ruby_extractor



module ExtractRuby
  class Ex
    include Ruby_extractor,Utils
  end

  class RubyExtractotr < Ex

    # attr_reader :two_dependencies
    attr_reader :package_list

    def initialize pool_num = 10
      @package_list       = Array.new()       # [name, version, status] package list , not exist "\n"
      @failure_list       = Array.new()       # parse failure list , exist "\n"
      @license_list       = Array.new()       # success List
      # @two_dependencies   = Array.new()       # gemfile.lock two dependencies
      #@pool              = Thread.pool(pool_num)
      @parse_error_st    	= 33
      @rubygems_not_found = 30               # rubygemsDB not found

    end

    def get_package
      @package_list
    end

    def get_failurelist
      @failure_list
    end

    # description : parse ruby package(name,version) from gemfile.lcok file
    #             : old rule,
    # repo_path   : repo path , type : String
    # st_true     : Correct extraction
    # st_error    : Extraction failed, you need to manually
    def parse_gemfile_lock(repo_path, st_true = 10, st_error = @parse_error_st)
    	path = Obtain_path.new(repo_path, "gem", ".lock").get_data
      #@failure_list.concat(path)
      if path.size == 0
        p 'gemfile.lock is null,ruby package is null'
        return -1
      end
      path.each do |ph|
        data = File.readlines(ph)
        @failure_list.concat(extract_ruby(data, @package_list, st_true, st_error))
      end
    end

    # # https://gist.github.com/flavio/1722530
    # https://github.com/bundler/bundler/blob/master/lib/bundler/lockfile_parser.rb
    # description : use bundler extract ruby package from gemfile.lcok
    # repo_path   : local repo path , type : String
    # st_true     : Correct extraction 10
    # s.source.options['tag']
    def parse_bundler(repo_path, st_true = 10)
      path = Obtain_path.new(repo_path, "gem", ".lock").get_data
      if path.size == 0
        p 'gemfile.lock is null,ruby package is null'
        return -1
      end
      path.each do |ph|
        data = File.readlines(ph)
        lockfile = Bundler::LockfileParser.new(Bundler.read_file(ph))
        lockfile.specs.each do |s| # if no package then .each == 0
          #@package_list.push [s.name, s.version.to_s, st_true]
          ps = Hash.new
          ps['name']    = s.name
          ps['version'] = s.version.to_s
          ps['st']      = st_true
          str = ''
          if s.source.options['uri'] != nil #['tag'] ['revision']
            ps['uri'] = s.source.options['uri']
          elsif s.source.options['remotes'] != nil
            s.source.options['remotes'].each{ |row|
              str += row + ','
            }
            ps['remotes'] = str[0 .. -2]
          end
          @package_list << ps
          # two dependencies
          # s.dependencies.each{|rows|
          #   tmp = Array.new
          #   tmp.concat([rows.name])
          #   #print rows.name
          #   rows.requirement.requirements.each{|row|
          #     tmp.concat [[row[0], row[1].version]]
          #   }
          #   tmp.concat [rows.type]
          #   @two_dependencies << tmp
          # }

        end
      end
    end # def parse_bundler


    def select_rubygems_db
      require_relative '../lib/api/gem_data'
      rubygems_result = Array.new
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
            pack_hash[:cmt]          = nil
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
    end # def select_rubygems_db

    # description : remove duplicate package
    def remove_duplicate
      # "rack,1.5.2,rack (1.5.2)" ==> "rack,1.5.2"
      @package_list.each do |package|
        package.replace(package.split(',')[0] + ',' + package.split(',')[1])
      end
      # 1 ... 7 ==> 1,2,3,4,5,6  Range
      for i in (0 ... @package_list.size) do
        for j in (i + 1 ... @package_list.size) do
          if @package_list[i] != nil and @package_list[i] == @package_list[j]
            #p @package_list[j]
            @package_list[j] = nil
          end
        end
      end
      @package_list.compact!
    end # def remove_duplicate

    

    def web_crawl
      @package_list.each do |package|
        p package
        @license_list << rubygems(package)
       # @pool.process{
       #   @license_list << rubygems(package)
       # }

      end
      #@pool.shutdown
      if @package_list.size != @license_list.size
        p "There are unfinished"
      end
    end # def web_crawl

  end # class RubyExtractotr

end # module ExtractRuby

if __FILE__ == $0
  url = '/home/li/luowq/test_repo/go-buildpack'
  url = '/home/li/luowq/test_repo/cf-cassandra-release/Gemfile.lock'
  ruby = ExtractRuby::RubyExtractotr.new;
  ruby.parse_bundler(url)
  ruby.package_list.each{|value| p value}
  p "!!!!!!!!!!!!!!!!!!!!!!!!"
  ruby.select_rubygems_db.each{|value| p value }
  #
  #p "!!!!!!!!!!!!!!!!!!!!!!!!"
  #ruby.web_crawl
end























