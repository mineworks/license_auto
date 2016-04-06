require 'pathname'
require 'license_auto/config/config'
require 'license_auto/logger'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'license_auto'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'license_auto/website'
require 'license_auto/matcher'
require 'license_auto/package'
require 'license_auto/repo'
require 'license_auto/license_info_wrapper'
require 'license_auto/exceptions'

