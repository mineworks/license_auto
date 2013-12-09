module LicenseAuto

end


$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'license_auto'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require './config/application'
# require './config/boot'


# You SHOULD Require website first
require './lib/license_auto/matcher'
require './lib/license_auto/website'
Dir[File.expand_path('../license_auto/website/*.rb', __FILE__)].each do |f|
  require f
end

Dir[File.expand_path('../license_auto/*.rb', __FILE__)].each do |f|
  require f
end

