# TODO: move to units.rb
class License_recognition
  def initialize(path = '')
    @license_text = ''
    @local_license_list = Array.new
    @local_license_path = path
    @high_frequency     = ['MIT','MIT2.0','Apache2.0','RubyClause-6','BSD',
                           'GPL2.0','GPL3.0','LGPL2.1','LGPL3.0']   # Often used license name
    @license_extension  = ".txt"      # Local license file extensions
    @similar_list       = Array.new
    @overload           = 20000       # Text is too long, unable to identify
    @condition          = 0.85        # Similarity value
  end

  # description : Find the smallest
  def min(a, b, c)
    i = a;
    i = b if i > b
    i = c if i > c
    return i
  end

  # description : Find the largest
  def max(a, b, c)
    i = a;
    i = b if i < b
    i = c if i < c
    return i
  end

  # description : edit distance
  def edit_distance(a, b)
    array = Array.new(2){Array.new(a.size+1)}
    array[0][0] = 0
    for i in (1 .. a.size)
      array[0][i] = i
    end

    for i in (1 .. b.size)
      array[i%2][0] = i
      for j in (1 .. a.size)
        if b[i - 1] == a[j - 1]
          array[i%2][j] = array[(i - 1)%2][j - 1]
        else
          array[i%2][j] = min(array[i%2][j - 1],array[(i - 1)%2][j - 1],array[(i - 1)%2][j]) + 1
        end
      end
    end
    return array[i%2][j]

  end

  # description : longest common substring
  def longest_common_substring(a, b)
    array = Array.new(2){Array.new(a.size+1)}
    array[0][0] = 0
    for i in (1 .. a.size)
      array[0][i] = 0
    end

    for i in (1 .. b.size)
      array[i%2][0] = 0
      for j in (1 .. a.size)
        if b[i - 1] == a[j - 1]
          array[i%2][j] = array[(i - 1)%2][j - 1] + 1
        else
          array[i%2][j] = max(array[i%2][j - 1],array[(i - 1)%2][j - 1],array[(i - 1)%2][j])
        end
      end
    end
    return array[i%2][j]
  end

  # description : License name list is sorted, commonly used on the front
  # constant    : License often used list
  # change      : Waiting list license change
  def sequence(constant = @high_frequency, change = @local_license_list)
    i = 0
    for j in (0 ... constant.size)
      #p constant[j]
      for k in (i ... change.size)
        if constant[j] == change[k][1]
          tmp = change[i]
          change[i] = change[k]
          change[k] = tmp
          i += 1
          break
        end
      end
    end
  end

  # description : Get all the local license file path
  # path        : Local license folder
  def get_local_license(path = @local_license_path)
    #p @high_frequency
    if File.directory?(path)
      Dir.foreach(path) do |file|
        if file != "." and file != ".." and !File.directory?(file) and File.extname(file) == @license_extension
          @local_license_list << [File.expand_path(path + '/' + file), File.basename(file,@license_extension)]
        end
      end
    else
      raise("path: #{path} not found!")
    end
    sequence()
    return @local_license_list
  end


  def sort_insert(data)
    flag = false
    if @similar_list.size == 0
      @similar_list << data
    else
      for i in (0 ... @similar_list.size)
        if data[0] > @similar_list[i][0]
          @similar_list.insert(i,data)
          flag = true
          break
        end
      end
      if false == flag
        @similar_list << data
      end
    end
  end

  # description : similarity
  # 0%          : Not the same
  # 100%        : The same
  # packge_license : Unrecognized text
  # path           : local license text
  def similarity(packge_license, path)

    get_local_license(path)

    package_licen_data = packge_license.scan(/\w+/)
    # Text is too long, unable to identify, then return null
    if package_licen_data.size > @overload
      return nil
    end
    local_license_date = Array.new
    @local_license_list.each do |license|
      local_license_date.clear
      local_file = File.readlines(license[0])
      local_file.each do |line|
        local_license_date.concat(line.scan(/\w+/))
      end
      ed = edit_distance(package_licen_data,local_license_date)
      lcs = longest_common_substring(package_licen_data,local_license_date)
      similar = (lcs + 0.0)/(ed + lcs)
      #p license[1]
      tmp = [similar, license[1], "ed[#{ed}]", "lcs[#{lcs}]", "web[#{package_licen_data.size}]", "local[#{local_license_date.size}]"]
      sort_insert(tmp)

      if similar > @condition
        return license[1]
      end
    end

    # p @similar_list

    if @similar_list.size == 0
      return nil
    elsif @similar_list[0][0] > 0.76
      return @similar_list[0][1]
    elsif @similar_list[0][0] > 0.45
      return @similar_list[0][1]
    else
      return nil
    end
  end # def similarity

  def extract_license_text_from_readme(readme)
    if File.extname(readme['name']) == '.rdoc'
      regular_start = /^==[ *](copying|copy|license){1}:*/i
      regular_end   = /^== /
    elsif File.extname(readme['name']) == '.md'
      regular_start = /^##[ *](copying|copy|license){1}:*/i
      regular_end   = /^## /
    else
      return nil
    end

  end

end  # class License_recognition


if __FILE__ == $0
  license_text = 'Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
  a = License_recognition.new.similarity(license_text, "./Package_license")
  puts a
end

































