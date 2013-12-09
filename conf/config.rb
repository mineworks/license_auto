require 'log4r'
require 'pg'
require_relative '../lib/api/mq'

$debug = true

AUTO_ROOT = '/tmp/license_auto_cache'
LAUNCHPAD_SOURCE_DIR = "#{AUTO_ROOT}/lp"
MANIFEST_SOURCE_DIR = "#{AUTO_ROOT}/manifest"
if !File.exist?(AUTO_ROOT)
  Dir.mkdir(AUTO_ROOT)
end
if !File.exist?(LAUNCHPAD_SOURCE_DIR)
  Dir.mkdir(LAUNCHPAD_SOURCE_DIR)
end
if !File.exists?(MANIFEST_SOURCE_DIR)
  Dir.mkdir(MANIFEST_SOURCE_DIR)
end

STD_LICENSE_DIR = "./extractor_ruby/Package_license"

pf = Log4r::PatternFormatter.new(
  :pattern => "%d [%l]: %M",
  :date_format => "%Y/%m/%d %H:%M:%S"
)

HTTPARTY_DOWNLOAD_TIMEOUT = 480


Log4r::StderrOutputter.new('console', :formatter => pf)
if $debug
  filename = "auto.log"
else
  filename = "#{AUTO_ROOT}/#{rand(1000).to_s}.log"
end

Log4r::FileOutputter.new('logfile',
                         :filename => filename,
                         :trunc => $debug,
                         :formatter => pf,
                         :level=>Log4r::DEBUG)

$plog = Log4r::Logger.new('auto.log')
$plog.add('console', 'logfile')

def log_usage_example()
  $plog.debug "This is a message with level DEBUG"
  $plog.info "This is a message with level INFO"
  $plog.warn "This is a message with level WARN"
  $plog.error "This is a message with level ERROR"
  $plog.fatal "This is a message with level FATAL"
end

LICENSE_WEBSITE_URL = 'http://localhost:3000'

pg_conn_hash = {
    host: 'license_auto_dev',
    port: '5432',
    dbname: 'license_auto',
    user: 'postgres',
    password: 'admin'
}
$conn = PG::Connection.open(pg_conn_hash)

gem_conn_hash = {
    host: 'license_auto_dev',
    port: '5432',
    dbname: 'gemData',
    user: 'postgres',
    password: 'admin'
}
$gemconn = PG::Connection.open(gem_conn_hash)

$rmq = API::RabbitMQ.new(ENV['license_auto_rabbit_mq'])

# ActiveRecord::Base.establish_connection(
#     :adapter => "postgresql",
#     :username => "username",
#     :password => "password",
#     :database => "database"
# )
