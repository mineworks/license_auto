module API

  SOURCE_URL_PATTERN = {
    :github => /(?<protocol>http[s]?):\/\/(?<host>github\.com)\/(?<owner>.+)\/(?<repo>[^\/]+)(?<ext>\.git)?/,
    :bitbucket => /(?<protocol>http[s]?):\/\/(?<host>bitbucket\.org)\/(?<owner>.+)\/(?<repo>.+)(?<ext>\.git)?/
  }
end
