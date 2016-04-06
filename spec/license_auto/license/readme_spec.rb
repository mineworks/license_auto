require 'spec_helper'
require 'open-uri'
# require 'github/markup'
# require 'redcarpet'

require 'license_auto/license/readme'

describe LicenseAuto::Readme do
  before do
    readme_uri = 'https://raw.githubusercontent.com/rails/rails/master/README.md'
    stub_request(:get, readme_uri).
        to_return(:status => 200, :body => fixture(readme_uri), :headers => {})
  end

  let(:readme_uri) {'https://raw.githubusercontent.com/rails/rails/master/README.md'}

  # it 'parse readme.md file, find license section' do
  #   readme_content = open(readme_uri).read
  #   html = GitHub::Markup.render('foo.readme.md', readme_content)
  #   license_content = nil
  #   expect(html).to_not eq(nil)
  #   LicenseAuto.logger.debug(html.class)
  # end

  it 'regex match Markdown file, find license section' do
    readme_content = open(readme_uri).read
    markdown = LicenseAuto::Readme.new(readme_uri, readme_content)
    expect(markdown.license_content).to_not eq(nil)
    # LicenseAuto.logger.debug(html.class)
  end
end

