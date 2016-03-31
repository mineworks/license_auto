module API

class GemData
  require_relative '../db'
  def initialize
  end

  def get_gem(name, version)
    pack = nil
    if version == nil or version == ''
      pg_result = api_get_gemdata_by_name(name)
    else
      pg_result = api_get_gemdata_by_name_and_version(name, version)
    end
    if pg_result.ntuples > 0
      result = pg_result[0]
      pack = {
        :pack_name => result["name"],
        :pack_version => result["number"],
        :homepage => result["home"],
        :source_url => result["code"],
        :license => result["licenses"]
      }
    end

    pack
  end
end

end