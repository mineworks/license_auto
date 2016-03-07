class RubyGemsOrg
  # TODO: how to fetch the instance variable of {LicenseAuto::Package}?
  def self.get_license_info(gem_name='rubygems_api')
    client = Rubygems::API::Client.new
    response = client.gem_info(gem_name, 'json')
    puts 'fuck'
    if response.status_code == 200
      puts 'you'
      return LicenseAuto::LicenseInfo.new(response.body)
    end


  end
end