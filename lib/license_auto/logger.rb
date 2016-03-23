require 'log4r'

module LicenseAuto
  def self.logger
    return @logger if @logger
    level = Log4r::DEBUG
    @logger = Log4r::Logger.new("filelog") # create a logger
    @logger.trace = true
    @logger.level = level
    @logger.add(Log4r::Outputter.stderr)
    @logger.add(Log4r::Outputter.stdout)


    # stderr_output = Log4r::StderrOutputter.new('stderr')
    stdout_output = Log4r::StdoutOutputter.new('stdout')
    file_output = Log4r::FileOutputter.new("file_output",
                                           :filename => "/tmp/license_auto.log",
                                           :trunc => false,
                                           :level => level,
                                           :trace => true
    )
    formatter = Log4r::PatternFormatter.new(
        :pattern => "%l %d %p - %M  %t",
    )
    # stderr_output.formatter = formatter
    stdout_output.formatter = formatter
    file_output.formatter = formatter

    @logger.outputters = [stdout_output, file_output]
    # @logger.outputters = [file_output]
    @logger
  end
end
