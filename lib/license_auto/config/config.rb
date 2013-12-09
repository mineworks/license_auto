require 'log4r'; Log4r::Logger.root
require 'yaml'
require 'hashie/mash'

# Aka LICENSE_AUTO_CONF
LUTO_CONF =
    begin
      Hashie::Mash.new(YAML.load_file('/etc/license_auto.conf.yml'))
    rescue Errno::ENOENT
      sample_filename_path = File.expand_path('../sample.config.yml', __FILE__)
      puts "Using config: #{sample_filename_path}"
      Hashie::Mash.new(YAML.load_file(sample_filename_path))
    end


# LicenseAuto logger level
LUTO_LOG_LEVEL =
    case LUTO_CONF.logger.level
    when 'debug'
      Log4r::DEBUG
    when 'info'
      Log4r::INFO
    when 'warn'
      Log4r::WARN
    when 'error'
      Log4r::ERROR
    when 'fatal'
      Log4r::FATAL
    else
      Log4r::DEBUG
    end

LUTO_ROOT_DIR = LUTO_CONF.dirs.root
LUTO_CACHE_DIR = "#{LUTO_ROOT_DIR}/#{LUTO_CONF.dirs.cache}"

unless FileTest.directory?(LUTO_CACHE_DIR)
  FileUtils.mkdir_p(LUTO_CACHE_DIR)
end
