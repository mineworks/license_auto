require 'hashie'

##
# package:
# Hash {
#     language: 'Ruby',                # Ruby|Golang|Java|NodeJS|Erlang|Python|
#     name: 'bundler',
#     group: 'com.google.http-client', # Optional: Assign nil if your package is not a Java
#     version: '1.11.2',               # Optional: Assign nil if check the latest
#     project_server: 'rubygems.org'   # Optional: github.com|rubygems.org|pypi.python.org/pypi|registry.npmjs.org
# }

class Package < Hash
  include Hashie::Extensions::MethodAccess

  attr_reader :language, :name
  attr_accessor :group, :version, :project_server



  def initialize(pack)
    self.instance = pack

    #   # TODO: detect latest version
    #   @version = nil
    #
    #   # TODO: fill default project_server
    #   @project_server = nil
  end

end
