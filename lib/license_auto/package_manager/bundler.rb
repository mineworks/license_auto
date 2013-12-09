require 'bundler'
require 'license_auto/package_manager'
require 'license_auto/website/ruby_gems_org'
# require 'license_auto/package_manager/gemfury'

module LicenseAuto
  class Bundler < LicenseAuto::VirtualPackageManager
    def initialize(path)
      super(path)
    end

    def dependency_file_pattern
      /gem.*\.lock/i
    end

    def gemfile_pattern
      /Gemfile$/i
    end

    def parse_dependencies
      # gemfiles = dependency_file_path_names(pattern=gemfile_pattern)
      # definition = ::Bundler::Definition.build(gemfiles.first, nil, nil)

      # definition.dependencies.each {|dep|
      #   LicenseAuto.logger.debug(dep.name + ' ' + dep.source.remotes.to_s)
      # }

      dep_files = dependency_file_path_names
      .map {|dep_file|
        lockfile_parser = ::Bundler::LockfileParser.new(::Bundler.read_file(dep_file))
        lockfile_parser.specs
      }
      .map {|specs|
        specs.map {|spec|
          remote =
              case
                when spec.source.class == ::Bundler::Source::Git
                  spec.source.uri
                when spec.source.class == ::Bundler::Source::Rubygems
                  if spec.source.remotes.size == 1
                    spec.source.remotes.first.to_s
                  elsif spec.source.remotes.size >= 1
                    # remotes =
                    #     if Gems.info(spec.name) == RubyGemsOrg::GEM_NOT_FOUND
                    #       spec.source.remotes.reject {|uri|
                    #         uri.to_s == RubyGemsOrg::URI
                    #       }
                    #     else
                    #       spec.source.remotes
                    #     end
                    spec.source.remotes.map {|r|
                      r.to_s
                    }.join(',')
                  end
                when spec.source.class == ::Bundler::Source::Path::Installer
                  # Untested
                  spec.full_gem_path
                else
                  # TODO:
                  # LicenseAuto.logger.debug(spec.source.class)
                # remotes = s.source.options['remotes']
              end

          {
              name: spec.name,
              version: spec.version.to_s,
              remote: remote
          }
        }
      }
      LicenseAuto.logger.debug(JSON.pretty_generate(dep_files))
    end
  end
end