module LicenseAuto
  module Matcher

    ##
    # Match all kinds of source_url by their regex patterns.
    #
    # The follow website URLs can get clear matched result:
    # * https://github.com
    # * https://bitbucket.org
    # * https://rubygems.org
    # * https://googlesource.com
    # * https://code.google.com
    # * https://gopkg.in
    # * https://golang.org

    class SourceURL

      attr_reader :url

      ##
      # Struct a new matcher by url

      def initialize(url)
        @url = url
      end

      def match_github_resource()
        github_resource.match(@url)
      end

      def match_bitbucket_resource
        github_resource.match(@url)
      end

      def match_maven_default_central
        maven_default_central_resource.match(@url)
      end

      private

      ##
      # vcs: Version Control System

      def maven_default_central_resource
        /repo1\.maven\.org\/maven2/
      end

      # FIXME: @Cissy
      def github_resource
        # /(git\+)?(?<protocol>(http[s]?|git))(:\/\/|@)(?<host>(www\.)?github\.com)(\/|:)(?<owner>.+)\/(?<repo>[^\/.]+)(?<vcs>\.git)?/
        /(git\+)?
        (?<protocol>(http[s]?|git))?
        (:\/\/|@)?
        (?<host>(www\.)?github\.com)
        (\/|:)
        (?<owner>.+)\/
        (?<repo>[^\/.]+)
        (?<vcs>\.git)?/x
      end

      def bitbucket_resource
        /(?<protocol>http[s]?):\/\/(?<host>bitbucket\.org)\/(?<owner>.+)\/(?<repo>.+)(?<vcs>\.git)?/
      end
    end


    class FilepathName

      attr_reader :name

      LICENSE_PATTERN = /(((?<license_name>.*)[-_])?licen[sc]e|copying|copyright|copyleft)+/i
      NOTICE_PATTERN = /notice/i
      README_PATTERN = /readme(?<extension>\..*)?/i

      ##
      # Debian Linux doc:
      #   [4.2. copyright. Required files under the debian directory](https://www.debian.org/doc/manuals/maint-guide/dreq.en.html#copyright)
      DPKG_COPYRIGHT_PATTERN = /^[^\/]+\/debian\/copyright$/



      def initialize(name)
        @name = name
      end

      def match_license_file()
        LICENSE_PATTERN.match(@name)
      end

      def match_readme_file()
        README_PATTERN.match(@name)
      end

      def match_notice_file()
        NOTICE_PATTERN.match(@name)
      end

      ##
      # git ref: commit hash/branch/tag
      def match_the_ref(ref)
        # LicenseAuto.logger.debug(ref)
        version_pattern = /[vV]?#{@name.gsub(/\./, '\.').gsub(/\//, '\/')}$/i
        # LicenseAuto.logger.debug(version_pattern)
        version_pattern.match(ref)
      end


    end
  end
end