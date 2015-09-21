require 'csv'


class Read_local_data
  def initialize path
    @csv_path = path
    @data     = Array.new()
  end

  # package Name,language,Version, URL,License,Reponame
  def read_data
    CSV.foreach(@csv_path) do |row|
      @data << row
    end
  end

  def destroy
    @data.clear
  end

  # description : search licnese infomation from local data
  # name        : package name ,    type : String
  # version     : pacakge version , type : String
  # return      : if find return license info , else return ''
  def search_package(name,version)
    target = ''
    @data.each do |row|
      if row[0] == name and row[1] == 'ruby' and row[2] == version
        # name, version, license, url
        return name + ',' + version + ',' + row[4] + ',' + row[3] + ",\n"
      end
    end
    return ''
  end # def search_package

end

