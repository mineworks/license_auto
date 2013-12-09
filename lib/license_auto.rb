module LicenseAuto

end

require './config/application'
# require './config/boot'


# You SHOULD Require website first
Dir[File.expand_path('../license_auto/website/*.rb', __FILE__)].each do |f|
  require f
end

Dir[File.expand_path('../license_auto/*.rb', __FILE__)].each do |f|
  require f
end

