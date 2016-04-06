LICENSE_TITLE = 'copying|copy|license'

module LicenseAuto


  class Readme

    # RDOC_EXT = /\.rdoc$/
    # RDOC_PATTERN = //
    #
    # RST_EXT = /\.rst/
    # RST_PATTERN = //

    attr_reader :license_content

    def initialize(filename, content)
      impl = formator(filename)
      @license_content = impl.cut_license(content)
    end

    def extensions
      [Markdown]
    end

    def formator(filename)
      extensions.find { |format|
        format::FILE_EXTENSION.match(filename)
      }
    end
  end

  class Markdown
    FILE_EXTENSION = /\.(md|markdown)$/i
    PATTERN = /(?<text>^##\s*(license|copy|copying)(.*\n*)*)($|(?=\n^##))/i

    def self.cut_license(content)
      matched = PATTERN.match(content)
      if matched
        matched[:text]
      end
    end
  end
end
