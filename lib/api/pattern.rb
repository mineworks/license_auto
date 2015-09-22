module API

  SOURCE_URL_PATTERN = {
    :github => /(?<protocol>http[s]?):\/\/(?<host>github\.com)\/(?<owner>.+)\/(?<repo>[^\/]+)(?<ext>\.git)?/,
    :bitbucket => /(?<protocol>http[s]?):\/\/(?<host>bitbucket\.org)\/(?<owner>.+)\/(?<repo>.+)(?<ext>\.git)?/
  }
  FILE_NAME_PATTERN = {
    :license_file => /(licen[sc]e|copying)+/i,
    :readme_file => /readme/i
  }
end
