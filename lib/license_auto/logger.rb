require 'log4r'
require 'license_auto/config/config'

module LicenseAuto
  def self.logger
    return @logger if @logger
    @logger = Log4r::Logger.new("license_auto")
    @logger.trace = true
    @logger.level = LUTO_LOG_LEVEL

    @logger.add(Log4r::Outputter.stderr)
    @logger.add(Log4r::Outputter.stdout)

    stdout_output = Log4r::StdoutOutputter.new('stdout')
    file_output = Log4r::FileOutputter.new("file_output",
                                           :filename => LUTO_CONF.logger.file,
                                           :trunc => false,
                                           :level => LUTO_LOG_LEVEL)
    formatter = Log4r::PatternFormatter.new(:pattern => "%l %d %p - %M  %t")
    stdout_output.formatter = formatter
    file_output.formatter = formatter

    @logger.outputters = [stdout_output, file_output]

    @logger
  end
end
