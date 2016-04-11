# license_auto
 
![Progress](http://progressed.io/bar/10?title=progress)
[![Gem Version](https://badge.fury.io/rb/license_auto.svg)](https://badge.fury.io/rb/license_auto)
[![Code Climate](https://codeclimate.com/github/mineworks/license_auto/badges/gpa.svg)](https://codeclimate.com/github/mineworks/license_auto)
[![Build Status](https://travis-ci.org/mineworks/license_auto.svg?branch=master)](https://travis-ci.org/mineworks/license_auto)

[license_auto](https://github.com/mineworks/license_auto) is a Ruby Gem for Open Source License collection job inspired by [LicenseFinder](https://github.com/pivotal/LicenseFinder)

### Dependencies Management Detecting Implement Details
<table>
  <tr>
    <th>Language</th>
    <th>DepsMgmt Program</th>
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
    <td>50</td>
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
* NodeJS v5.7.0+
* npm v3.6.0
* Python pip v1.5.6
* go v1.4.2

## Install
``` bash
gem install license_auto
```

## Configure
```
sudo cp license_auto/config/sample.config.yml etc/license_auto.conf.yml
cp license_auto/config/gitconfig ~/.gitconfig
```

## Examples

* Get dependencies of a repository
``` ruby
require 'license_auto'
my_repo = {
  "clone_url": "https://github.com/mineworks/license_auto.git",
  "ref": "test-branch"
}
repo = LicenseAuto::Repo.new(my_repo)
dependencies = repo.find_dependencies
```

* Get License Info of a package
``` ruby
require 'license_auto'
my_pack = {
    language: 'Ruby',                # Ruby|Golang|Java|NodeJS|Erlang|Python|
    name: 'bundler',
    group: 'com.google.http-client', # Optional: Assign nil if your package is not a Java
    version: '1.11.2',               # Optional: Assign nil if check the latest
    server: 'rubygems.org'   # Optional: github.com|rubygems.org|pypi.python.org/pypi|registry.npmjs.org
}
package = LicenseAuto::Package.new(my_pack)
license_info = package.get_license_info()
puts license_info.licenses
# => #<Hashie::Mash _links=#<Hashie::Mash git="https://api.github.com/repos/bundler/bundler/git/blobs/e356f59f949264bff1600af3476d5e37147957cc" html="https://github.com/bundler/bundler/blob/v1.11.2/LICENSE.md" self="https://api.github.com/repos/bundler/bundler/contents/LICENSE.md?ref=v1.11.2"> download_url="https://raw.githubusercontent.com/bundler/bundler/v1.11.2/LICENSE.md" git_url="https://api.github.com/repos/bundler/bundler/git/blobs/e356f59f949264bff1600af3476d5e37147957cc" html_url="https://github.com/bundler/bundler/blob/v1.11.2/LICENSE.md" name="LICENSE.md" path="LICENSE.md" sha="e356f59f949264bff1600af3476d5e37147957cc" size=1118 type="file" url="https://api.github.com/repos/bundler/bundler/contents/LICENSE.md?ref=v1.11.2">
```

## Test
``` bash
rake spec
```

## TODO
* Check My `Gemfile` licensing for legal issues safe
* Speed up License name recognizing.
* Groovy gradle
* CMake
* Fork Github official licenses text sample
