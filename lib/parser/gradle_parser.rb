require_relative '../../conf/config'
require_relative '../misc'

require 'open3'

module API
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
      projects = ['.']
      cmd = "gradle -q project"
      Open3.popen3(cmd) {|i,o,e,t|
        out = o.readlines
        error = e.readlines
        if error.length > 0
          $plog.error(error)
          raise "#{self.class}.list_projects error: #{cmd}, #{error}"
        elsif out.length > 0
          out.each {|line|
            pattern = /[P]roject\s\'(:)?(?<project_name>.+)\'/
            match_result = pattern.match(line)
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

    def list_dependencies(project_name)
      dependencies = Set.new
      # TODO: list all projects' dependencies in one time
      # cmd = "gradle -q dependencies #{project_name_1}:dependencies #{project_name_2}:dependencies ..."
      cmd = "gradle -q dependencies -p #{project_name}"
      $plog.debug(cmd)
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

    # def insight_dependencies(project_name, dependency_name)
    #   match_result = @deps_pattern.match(dependency_name)
    #   if match_result
    #     name = match_result[:name]
    #     $plog.debug(name)
    #     conf = " --configuration compile"
    #     cmd = "gradle -q #{project_name}:dependencyInsight --dependency #{name}"
    #     $plog.debug(cmd)
    #   end
    #
    # end

    def start
      all_projects_deps = Set.new
      build_dot_gradle = find_build_dot_gradle.first

      if build_dot_gradle
        $plog.debug(build_dot_gradle)
        Dir.chdir(@repo_path) {
          projects = list_projects
          $plog.debug("projects: #{projects}")
          projects.each {|project_name|
            # TODO: remove test data :app
            # project_name = 'app'
            dependencies = list_dependencies(project_name)
            # $plog.debug("dependencies: #{dependencies}")
            all_projects_deps = all_projects_deps.merge(dependencies)

            # dependencies.each {|dep|
            #   $plog.debug(dep)
            #   # insight_dependencies(project_name, dep)
            # }
          }

        }
      else
        $plog.info("There is no build.gradle script in #{@repo_path}")
      end
      all_projects_deps
    end
  end
end

if __FILE__ == $0
  # p = '/tmp/license_website/github.com/java-decompiler/jd-gui/build'
  p = '/tmp/license_website/github.com/java-decompiler/jd-gui'
  g = API::GradleParser.new(p)
  all_projects_deps = g.start
  $plog.debug("#{all_projects_deps}")
  all_projects_deps.each {|d|
    p d
  }

end
