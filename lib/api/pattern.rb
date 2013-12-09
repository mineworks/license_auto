module API

  SOURCE_URL_PATTERN = {
    :github => /(?<protocol>http[s]?):\/\/(?<host>(www\.)?github\.com)\/(?<owner>.+)\/(?<repo>[^\/]+)(?<ext>\.git)?/,
    :bitbucket => /(?<protocol>http[s]?):\/\/(?<host>bitbucket\.org)\/(?<owner>.+)\/(?<repo>.+)(?<ext>\.git)?/
  }
  FILE_NAME_PATTERN = {
    :license_file => /(licen[sc]e|copying)+/i,
    :readme_file => /readme/i
  }
  FILE_TYPE_PATTERN = {
    :tar_gz => /tar\.gz$/,
    :tar_xz => /tar\.xz$/,
    :tar_bz2 => /tar\.bz2$/
  }
  OS_PATTERN = {
    :ubuntu => /^(?<distribution>(Ubuntu))-(?<distro_series>(Trusty))/i,
    :centos => /^(?<distribution>(CentOS))-(?<distro_series>(7\.x))/i,
  }
end
