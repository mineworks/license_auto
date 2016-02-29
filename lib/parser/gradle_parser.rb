require_relative '../../conf/config'
require_relative '../misc'

require 'open3'

class GradleParser
  def initialize(repo_path)
    @repo_path = repo_path
    @build_dot_gradle_pattern = /#{repo_path}\/build\.gradle$/
    @deps_pattern = /(?<group>.+):(?<name>.+):(?<version>.+)/
  end

  def find_build_dot_gradle
    filenames = Misc::DirUtils.new(@repo_path).filter_filename(@build_dot_gradle_pattern)
  end

  def list_projects
    projects = []
    cmd = "gradle -q project"
    Open3.popen3(cmd) {|i,o,e,t|
      out = o.readlines
      error = e.readlines
      if error.length > 0
        $plog.error(error)
        raise "#{self.class}.list_projects error: #{cmd}, #{error}"
      elsif out.length > 0
        out.each {|line|
          # root_project_pattern = /Root\sproject\s\'(?<project_name>.+)\'/
          # root_match_result = root_project_pattern.match(line)
          # if root_match_result != nil
          #   projects.push(root_match_result[:project_name])
          # end

          sub_project_pattern = /Project\s\'(:)?(?<project_name>.+)\'/
          match_result = sub_project_pattern.match(line)
          if match_result != nil
            projects.push(match_result[:project_name])
          end
        }
      else
        raise "#{self.class}.list_projects error error: #{cmd}, #{error}"
      end
    }
    projects
  end

  def list_dependencies(project_name=nil)
    dependencies = Set.new
    cmd = if project_name
            # Sub project
            "gradle -q #{project_name}:dependencies"
          else
            # Root project
            "gradle -q dependencies"
          end
    $plog.debug("cmd: #{cmd}")
    Open3.popen3(cmd) {|i,o,e,t|
      out = o.readlines
      error = e.readlines
      if error.length > 0
        $plog.error(error)
        raise "#{self.class}.list_dependencies error: #{cmd}, #{error}"
      elsif out.length > 0
        out.each {|line|
          pattern = /---\s(?<dep_name>.+)/
          match_result = pattern.match(line)
          if match_result != nil
            dep_name = match_result[:dep_name]
            if dep_name =~ /project\s:.+/
              nil
            elsif dep_name =~ @deps_pattern
              # External dependencies
              # DOC: https://docs.gradle.org/current/userguide/artifact_dependencies_tutorial.html#N105E1
              dependencies.add(dep_name)
            else
              # Maybe a file .jar
              raise "Uncoverd gradle deps_pattern: #{dep_name}"
            end
          end
        }
      else
        raise "#{self.class}.list_dependencies error error: #{cmd}, #{error}"
      end
    }
    dependencies
  end

  def start
    all_projects_deps = Set.new
    find_build_dot_gradle.each {|build_dot_gradle|
      if build_dot_gradle
        $plog.debug(build_dot_gradle)
        Dir.chdir(@repo_path) {
          all_projects_deps = all_projects_deps.merge(list_dependencies)
          projects = list_projects
          $plog.debug("projects: #{projects}")
          projects.each {|project_name|
            dependencies = list_dependencies(project_name)
            $plog.debug("dependencies: #{dependencies.to_a}")
            all_projects_deps = all_projects_deps.merge(dependencies)
          }
        }
      else
        $plog.info("There is no build.gradle script in #{@repo_path}")
      end
      all_projects_deps.map {|group_name_version|
        group, name, version = group_name_version.split(':')

        # 'junit:junit:3.8.2 -> 4.11'
        range_arrow_pattern = /(?<min_ver>.*)\s->\s(?<max_ver>.*)/
        is_range_version = range_arrow_pattern.match(version)
        if is_range_version
          version = is_range_version[:max_ver]
        end

        # 'org.apache.ant:ant:1.8.3 (*)'
        star_pattern = /\s\(\*\)/
        version = version.gsub(star_pattern, '')

        {
            group: group,
            name: name,
            version: version
        }
      }
    }
  end
end

if __FILE__ == $0
  # p = '/tmp/license_website/github.com/java-decompiler/jd-gui/build'
  p = '/tmp/license_website/github.com/java-decompiler/jd-gui'
  p = '/Users/mic/vm/uaa'
  g = GradleParser.new(p)
  all_projects_deps = g.start
  $plog.debug("#{all_projects_deps}")
  all_projects_deps.each {|d|
    p d
  }

end
