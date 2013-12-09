require 'minitest/spec'
require 'minitest/autorun'

require_relative '../lib/cloner'
require_relative '../config/config'
require_relative '../lib/parser/golang_parser'

describe 'GolangTest' do
  it "can be download a repo, parse its deps, extract license name, give latest commit hash" do
    repo = 'http://github.com/micfan/dinner'
    clone_path = Cloner::clone_repo(repo)
    pack__license__name_filepaths = GolangParser.start(clone_path)
    pack__license__name_filepaths.wont_be_nil
  end
end