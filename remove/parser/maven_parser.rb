require 'open3'
require_relative '../misc'

class MavenParser

  def initialize(repo_path)
    @repo_path = repo_path
    @package_list = Array.new
    @pom_xml = /pom.xml/
  end

  def find_build_dot_pom
    filenames = Misc::DirUtils.new(@repo_path).filter_filename(@pom_xml)

    if filenames.size == 0
      return false
    else
      return true
    end
  end

  def start

    if find_build_dot_pom == false
      return []
    end

    cmd = 'mvn dependency:resolve'
    flag = false
    Dir.chdir(@repo_path)
    Open3.popen3(cmd) {|i,o,e,t|
      out = o.readlines
      error = e.readlines
      if error.length > 0
        # TODO
      elsif out.length > 0
        out.each do |row|
          flag = true if row == "[INFO] BUILD SUCCESS\n"
        end
      else
        # TODO
      end
    }
    if flag
      cmd = 'mvn dependency:list'
      flag = false
      packages = []
      Dir.chdir(@repo_path)
      Open3.popen3(cmd) {|i,o,e,t|
        out = o.readlines
        error = e.readlines
        if error.length > 0
          # TODO
        elsif out.length > 0
          out.each do |row|
            # p row
            if row == "[INFO] The following files have been resolved:\n"
              flag = true
            elsif row == "[INFO] \n"
              flag = false
            elsif flag == true
              packages << row
            end
          end
        else
          # TODO
        end
      }
      packages.each do |line|
        line.gsub!(/\[INFO\]/,'').strip!
        pack = line.split("\:")
        @package_list << {
            :group   =>pack[0],
            :name    =>pack[1],
            :version => pack[3]
        }
      end
    end

    return @package_list
  end

end

if __FILE__ == $0
  path = "/home/li/ruby/maximus-master"
  packs = MavenParser.new(path).start
  packs.each do |row|
    p row
  end
end
