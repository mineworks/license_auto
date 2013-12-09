module Website

  def initialize(package)
    @package = package
  end

  def get_license_info()
    client = Rubygems::API::Client.new
    response = client.gem_info(@package.name, 'json')
    if response.status_code == 200
      return LicenseAuto::LicenseInfo.new(response.body)
    end
  end

  def to_s
    @package
  end

end