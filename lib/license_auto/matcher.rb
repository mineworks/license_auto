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
        matched = github_resource.match(@url)
      end

      def match_bitbucket_resource
        matched = github_resource.match(@url)
      end

      private

      ##
      # vcs: Version Control System

      # FIXME: @Cissy
      def github_resource
        # /(git\+)?(?<protocol>(http[s]?|git))(:\/\/|@)(?<host>(www\.)?github\.com)(\/|:)(?<owner>.+)\/(?<repo>[^\/.]+)(?<vcs>\.git)?/
        /(git\+)?
        (?<protocol>(http[s]?|git))
        (:\/\/|@)
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

    # TODO:
    class FileName

    end
  end
end