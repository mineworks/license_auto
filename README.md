## license_auto(v0.1.0.beta) (unreleased)
[license_auto](https://github.com/mineworks/license_auto) is a Ruby Gem for Open Source License collection job.

### Dependencies Management Detecting Implement Details
<table>
  <tr>
    <th>Language</th>
    <th>Dependencies programs</th>
    <th>Dependencies file</th>
    <th>Default project servers</th>
    <th>Progress(%)</th>
  </tr>
  <tr>
    <td>Ruby</td>
    <td>bundler</td>
    <td>Gemfile(.lock)</td>
    <td>https://rubygems.org/</td>
    <!-- <td> https://rubygems.org/pages/data</td> -->
    <td>1</td>
  </tr>
  <tr>
    <td>Java</td>
    <td>Gradle, Maven</td>
    <td>build.gradle, pom.xml</td>
    <td>https://repo1.maven.org/maven2</td>
    <td>0</td>
  </tr>
  <tr>
    <td>NodeJS</td>
    <td>npm</td>
    <td>package.json</td>
    <td>http://registry.npmjs.org</td>
    <td>0</td>
  </tr>
  <tr>
      <td>Debian</td>
      <td>dpkg -l</td>
      <td></td>
      <td>https://launchpad.net/</td>
      <td>0</td>
  </tr>
  <tr>
    <td>Golang</td>
    <td>go list -json ./...</td>
    <td></td>
    <td></td>
    <td>0</td>
  </tr>
  <tr>
    <td>Python</td>
    <td>pip</td>
    <td>requirements.txt</td>
    <td>https://pypi.python.org/pypi</td>
    <td>0</td>
  </tr>  
  <tr>
    <td>Erlang</td>
    <td>rebar</td>
    <td>rebar.config</td>
    <td></td>
    <td>0</td>
  </tr>
</table>

## Requirements
* HTTP Network(WiFi on)
* HTTP proxy to Google.com is a plus
* Ruby v2.2.x
* bundler v1.10.x
* Gradle v2.9
* Maven v3.x
* Rebar v2.6.1
* npm v3.3.12
* Python pip v1.5.6
* go v1.4.2

## Install
``` bash
gem install license_auto
```

## Examples

* Optional: Config Github Auth
``` ruby
require 'license_auto'
# TODO: other parameters
params = {
    github_username: 'Alice'
    github_password: '123456',
    http_proxy: 'http://proxyuser:proxypwd@proxy.server.com:8080'
}
LicenseAuto::Base.config(params)
```

* Get dependencies of a repository
``` ruby
# TODO:
my_repo = {
  repo_url: 'https://github.com/mineworks/license_auto.git'
}
repo = LicenseAuto::Package.new(my_repo)
dependencies = repo.get_dependencies()
```

* Get License Info of a package
``` ruby
my_pack = {
    language: 'Ruby',                # Ruby|Golang|Java|NodeJS|Erlang|Python|
    name: 'bundler',
    group: 'com.google.http-client', # Optional: Assign nil if your package is not a Java
    version: '1.11.2',               # Optional: Assign nil if check the latest
    project_server: 'rubygems.org'   # Optional: github.com|rubygems.org|pypi.python.org/pypi|registry.npmjs.org
}
package = LicenseAuto::Package.new(my_pack)
license_info = package.get_license_info()
```

## Test
``` bash
$ rake spec
```

## TODO
* Check My `Gemfile` licensing for legal issues safe
* Speed up License name recognizing.
* Groovy gradle
* CMake
* Fork Github official licenses text sample
