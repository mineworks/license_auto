require 'license_auto'
my_pack = {
    language: 'Ruby',                # Ruby|Golang|Java|NodeJS|Erlang|Python|
    name: 'bundler',
    group: 'com.google.http-client', # Optional: Assign nil if your package is not a Java
    version: '1.11.2',               # Optional: Assign nil if check the latest
    server: 'rubygems.org'           # Optional: github.com|rubygems.org|pypi.python.org/pypi|registry.npmjs.org
}
package = LicenseAuto::Package.new(my_pack)
license_info = package.get_license_info()
puts license_info.licenses
# => #<Hashie::Mash _links=#<Hashie::Mash git="https://api.github.com/repos/bundler/bundler/git/blobs/e356f59f949264bff1600af3476d5e37147957cc" html="https://github.com/bundler/bundler/blob/v1.11.2/LICENSE.md" self="https://api.github.com/repos/bundler/bundler/contents/LICENSE.md?ref=v1.11.2"> download_url="https://raw.githubusercontent.com/bundler/bundler/v1.11.2/LICENSE.md" git_url="https://api.github.com/repos/bundler/bundler/git/blobs/e356f59f949264bff1600af3476d5e37147957cc" html_url="https://github.com/bundler/bundler/blob/v1.11.2/LICENSE.md" name="LICENSE.md" path="LICENSE.md" sha="e356f59f949264bff1600af3476d5e37147957cc" size=1118 type="file" url="https://api.github.com/repos/bundler/bundler/contents/LICENSE.md?ref=v1.11.2">
