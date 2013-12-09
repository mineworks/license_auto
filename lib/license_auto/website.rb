class Website

  # package: Hashie::Mash
  def initialize(package)
    @package = package
  end

  def to_s
    @package
  end

end