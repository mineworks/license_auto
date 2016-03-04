## license_auto
[license_auto](https://github.com/mineworks/license_auto) is a ruby gem for Open Source License collection job.

### Dependencies Management Detecting Implement Details
<table>
  <tr>
    <th>Language</th>
    <th>Dependencies programs</th>
    <th>Dependencies file</th>
    <th>Default project servers</th>
    <th>Optional</th>
    <th>Progress(%)</th>
  </tr>
  <tr>
    <td>Ruby</td>
    <td>bundler</td>
    <td>Gemfile(.lock)</td>
    <td>https://rubygems.org/</td>
    <td> https://rubygems.org/pages/data</td>
    <td>0</td>
  </tr>
  <tr>
    <td>Java</td>
    <td>Gradle, Maven</td>
    <td>build.gradle, pom.xml</td>
    <td></td>
    <td></td>
    <td>0</td>
  </tr>
  <tr>
    <td>NodeJS</td>
    <td>npm</td>
    <td>package.json</td>
    <td>http://registry.npmjs.org</td>
    <td></td>
    <td>0</td>
  </tr>
  <tr>
      <td>Debian</td>
      <td>dpkg -l</td>
      <td></td>
      <td>https://launchpad.net/</td>      
      <td></td>
      <td>0</td>
  </tr>
  <tr>
    <td>Golang</td>
    <td>go list -json ./...</td>
    <td></td>
    <td></td>
    <td></td>
    <td>0</td>
  </tr>
  <tr>
    <td>Python</td>
    <td>pip</td>
    <td>requirements.txt</td>
    <td>https://pypi.python.org/pypi</td>
    <td></td>
    <td>0</td>
  </tr>  
  <tr>
    <td>Erlang</td>
    <td>rebar</td>
    <td>rebar.config</td>
    <td></td>
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


## Design Principles
* Get resource by HTTP first. 

## Examples

### Optional: Config Github Auth
``` ruby
params = {
    github_username: 'alice'
    github_password: '123456',
}
auto = License::Auto.new().config(params)
```

### Optional:

TODO: config rubygems.org PostgreSQL database connection string if you have created one.

### Check dependencies of a repository
``` ruby
auto = License::Auto.new
repo = {
  repo_url: 'https://github.com/mineworks/license_auto.git'
}
dependencies = auto.get_dependencies(repo)
```

### Check License Info of a given package(library)
``` ruby
auto = License::Auto.new()
package = {
    language: 'Ruby',                # Ruby|Golang|Java|NodeJS|Erlang|Python|
    name: 'bundler',
    group: 'com.google.http-client', # Optional: Assign nil if your package is not a Java
    version: '1.11.2',               # Optional: Assign nil if check the latest
    project_server: 'rubygems.org'   # Optional: github.com|rubygems.org|pypi.python.org/pypi|registry.npmjs.org
}
license_info = auto.get_license_info(package)
```

# TODO
* Speed up License name recognizing.
* Groovy gradle
* CMake
* Fork Github official licenses text sample



