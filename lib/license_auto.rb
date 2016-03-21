require 'pathname'

module LicenseAuto

end


$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'license_auto'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

# puts $LOAD_PATH
# puts Pathname.new(__FILE__).dirname.join("license_finder")

# require 'license_auto/config/config'

require 'license_auto/website'
require 'license_auto/matcher'
require 'license_auto/package'
require 'license_auto/license_info'
require 'license_auto/exceptions'

