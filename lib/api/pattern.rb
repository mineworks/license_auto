module API

  SOURCE_URL_PATTERN = {
    :github => /(?<protocol>(http[s]?|git))(:\/\/|@)(?<host>(www\.)?github\.com)(\/|:)(?<owner>.+)\/(?<repo>[^\/.]+)(?<ext>\.git)?/,
    :git_kernel_org => /(?<protocol>http[s]?):\/\/(?<host>git\.kernel\.org)\/.+\/(?<owner>.+)\/(?<repo>[^\/.]+)(?<ext>\.git)?/,
    # DOC: https://docs.npmjs.com/files/package.json#git-urls-as-dependencies
    :npm_urls => /(?<protocol>git):\/\/(?<host>.*\..*)\/(?<owner>.+)\/(?<repo>[^\/#]+(\.git)?)(#(?<ref>.*))?/,
    :bitbucket => /(?<protocol>http[s]?):\/\/(?<host>bitbucket\.org)\/(?<owner>.+)\/(?<repo>.+)(?<ext>\.git)?/,
    :github_html_page => /(?<protocol>http[s]?):\/\/(?<host>(www\.)?github\.com)\/(?<owner>.+)\/(?<repo>[^\/]+)\/blob\/(?<branch>.+)\/(?<file_pathname>.+)?/,
    :github_dot_com => /github\.com/,
    :rubygems_org => /rubygems\.org/,
    :google_source_com => /(?<protocol>http[s]?):\/\/(?<owner>.+)\.(?<host>googlesource\.com)\/(?<repo>[^\/.]+)(?<ext>\.git)?/,
    :code_google_com => /(?<protocol>http[s]?):\/\/(?<host>code\.google\.com)\/(?<owner>p)\/(?<repo>[^\/.]+)?/,
    :go_pkg_in => /(?<protocol>http[s]?):\/\/(?<host>gopkg\.in)\/((?<owner>[^\/.]+)\/(?<repo>[^\/.]+)\.(?<ref>.+)|(?<repo>[^\/.]+)\.(?<ref>[^\/.]+))/,
    :golang_org => /(?<protocol>http[s]?):\/\/(?<host>.*golang\.org)\/(?<owner>[^\/.]+)\/(?<repo>[^\/.]+)/
  }
  FILE_NAME_PATTERN = {
    :license_file => /(licen[sc]e|copying)+/i,
    :readme_file => /readme/i,
    :components_yml => /components\.yml/,
    :notice_file => /(notice|copyright)/i
  }
  FILE_TYPE_PATTERN = {
    :tar_gz => /(tar\.gz|\.tgz)$/,
    :tar_xz => /tar\.xz$/,
    :tar_bz2 => /tar\.bz2$/
  }
  OS_PATTERN = {
    :ubuntu => /^(?<distribution>(Ubuntu))-(?<distro_series>(Trusty))/i,
    :centos => /^(?<distribution>(CentOS))-(?<distro_series>(7\.x))/i,
  }
end
