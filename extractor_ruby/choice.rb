require 'thread/pool'

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
    def initialize pool_num = 10
      #@gemfile_lock_path = Array.new();			  # gemfile.lock path , type : Array
      #@repo_name         = repo              # repo name         , type : String
      #@search_local_data = Read_local_data.new(local_data_path);
      @package_list      = Array.new()       # [name, version, status] package list , not exist "\n"
      #@gemfile_lock      = Array.new()       # gemfile.lock content  ,not exist "\n"
      @failure_list      = Array.new()       # parse failure list , exist "\n"
      @license_list      = Array.new()       # success List
      #@pool              = Thread.pool(pool_num)

    end

    def get_package
      @package_list
    end

    def get_failurelist
      @failure_list
    end

    # description : parse ruby package(name,version) from gemfile.lcok file
    # repo_path   : repo path , type : String
    # st_true     : Correct extraction
    # st_error    : Extraction failed, you need to manually

    def parse_gemfile_lock(repo_path, st_true = 10, st_error = 30)
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


    def select_rubygems_db
      require_relative '../lib/api/gem_data'
      ruby_pack = Array.new
      rubygems_result = Array.new

      ruby_pack.concat(@package_list)
      ruby_pack.concat(@failure_list)
      ruby_gems = API::GemData.new
      ruby_pack.each do |row|
        pack_hash = {
            :pack_name => nil,
            :pack_version => nil,
            :homepage => nil,
            :source_url => nil,
            :license => nil,
            :status => 10,
            :cmt => nil
        }
        if 10 == row[2]
          result = ruby_gems.get_gemdata(row[0],row[1])
          if result == nil and row[1].count('.')  == 1
            version = row[1] + '.0'
            result = ruby_gems.get_gemdata(row[0],version)
          end

          if result != nil
            pack_hash[:pack_name]    = result[:name]
            pack_hash[:pack_version] = result[:version]
            pack_hash[:homepage]    = result[:homepage]
            pack_hash[:source_url]   = result[:source_url]
            pack_hash[:license]      = result[:license]
            pack_hash[:status]       = row[2]
            pack_hash[:cmt]          = nil
          elsif nil == result
            pack_hash[:pack_name]    = row[0]
            if "" == row[1]
              pack_hash[:pack_version] = nil
            else
              pack_hash[:pack_version] = row[1]
            end
            pack_hash[:homepage]    = nil
            pack_hash[:source_url]   = nil
            pack_hash[:license]      = nil
            pack_hash[:status]       = 30
            pack_hash[:cmt]          = nil
          end

        elsif 30 == row[2]
          pack_hash[:pack_name]    = row[0]
          if "" == row[1]
            pack_hash[:pack_version] = nil
          else
            pack_hash[:pack_version] = row[1]
          end
          pack_hash[:homepage]    = nil
          pack_hash[:source_url]   = nil
          pack_hash[:license]      = nil
          pack_hash[:status]       = row[2]
          pack_hash[:cmt]          = nil
        end

        rubygems_result << pack_hash
      end

      return rubygems_result
    end # def select_rubygems_db

    # # description : record gemfile.lcok
    # def log_package
    #   log_path = out_path(@repo_name,1)
    #   write_file(log_path + "/gemfilelist.txt", @package_list,'w',1)
    #   log_path = out_path(@repo_name,2)
    #   write_file(log_path + "/failurelist.txt", @failure_list,'w',1)
    #
    # end # def log_package

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
      # output package list
      # log_path = out_path(@repo_name,1)
      # write_file(log_path + "/package_list.txt", @package_list,'w',1)
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

      # log_path = out_path(@repo_name,2)
      # write_file(log_path + "/package_license.csv",@license_list)
    end # def web_crawl

  end # class RubyExtractotr

end # module ExtractRuby

if __FILE__ == $0
  url = '/home/li/luowq/test_repo/insights'

  #ruby_path = Obtain_path.new(url,".lock").get_data
  #p ruby_path
  #ruby = ExtractRuby::RubyExtractotr.new(ruby_path,"insights",local_data_path)

  ruby = ExtractRuby::RubyExtractotr.new;
  ruby.parse_gemfile_lock(url)
  ruby.web_crawl
end























