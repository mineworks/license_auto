module API
  class Gradle
    def initialize(gradle_file)
      @gradle_file = gradle_file
      @websites = {
        mvn: 'http://mvnrepository.com/',
        maven: 'https://maven-repository.com/search',
        rpmfind: 'http://www.rpmfind.net/'
      }

    end

    # DOC: http://pkaq.github.io/gradledoc/docs/userguide/ch11/tutorial_gradle_command_line.html#sec:listing_dependencies
    def list_dependencies()
      deps = {
        :pack_name_1 => 'pack_version_1',
        :pack_name_2 => 'pack_version_2'
      }
    end

    # JSON: http://search.maven.org/solrsearch/select?q=g:%22org.apache.commons%22&rows=20&wt=json
    # JSON: http://search.maven.org/solrsearch/select?q=g:%22org.apache.commons%22%20AND%20a:%22commons-lang3%22&rows=2000&wt=json
    # JSON: http://search.maven.org/solrsearch/select?q=g:%22org.apache.commons%22%20AND%20a:%22commons-lang3%22%20AND%20v:%223.0%22&rows=2000&wt=json

    def fetch_license_info_from_website()
      license = nil
      license_url = nil
      license_text = nil
      source_code_download_url = nil
      source_package_page_link = nil
      license_info = {
        license: license,
        license_url: license_url,
        license_text: license_text,
        source_url: source_code_download_url,
        homepage: source_package_page_link
      }
    end
  end
end
