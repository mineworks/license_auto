module API

class GemData
  require_relative '../db'
  def initialize
    @name = ''
    @version = ''
  end

  def get_gemdata(name, version)
    @name = name
    @version = version
    pack = Hash.new()
    if version == nil or version == ''
      r = api_get_gemdata_by_name(@name)
    else
      r = api_get_gemdata_by_name_and_version(@name, @version)
    end
    if r == nil
      pack = r
    else
      pack[:name] = r["name"]
      pack[:version] = r["number"]
      pack[:homepage] = r["home"]
      pack[:source_url] = r["code"]
      pack[:license] = r["licenses"]
    end

    return pack
  end
end

end ### API