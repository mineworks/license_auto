require 'log4r'; Log4r::Logger.root

LOG_LEVEL =
 Log4r::DEBUG
 #  Log4r::INFO
 #  Log4r::WARN
 #  Log4r::ERROR
 #  Log4r::FATAL

HTTPARTY_DOWNLOAD_TIMEOUT = 480
LICENSE_AUTO_ROOT = '/tmp/license_auto'
LICENSE_AUTO_CACHE = "#{LICENSE_AUTO_ROOT}/cache"
