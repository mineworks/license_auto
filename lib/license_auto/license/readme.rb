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
      @content = content.encode('UTF-8', :invalid => :replace, :undef => :replace)
      impl = formator(filename)
      @license_content =
          if impl.nil?
            LicenseAuto.logger.info("Unknown readme format: #{filename}, returned full-text instead")
            @content
          else
             impl.cut_license(@content)
          end
    end

    def extensions
      [Markdown, RDoc]
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

  class RDoc
    FILE_EXTENSION = /\.rdoc$/i
    PATTERN = /(?<text>^==\s*(license|copy|copying)(.*\n*)*)($|(?=\n^==))/i

    def self.cut_license(content)
      matched = PATTERN.match(content)
      if matched
        matched[:text]
      end
    end
  end
end
