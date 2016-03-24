require 'pathname'
require 'license_auto/logger'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'license_auto'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'license_auto/website'
require 'license_auto/matcher'
require 'license_auto/package'
require 'license_auto/license_info'
require 'license_auto/exceptions'

