# TODO: move to utils.rb
class Obtain_path
	
	def initialize(ph, f_name, ex)
		@path             = ph;						# Search for files
		@target_file_path = Array.new();	# Find the file path
		@file_name 				= f_name				# Limits file names
		@extension        = ex;						# File extension
		##判断是路径名还是文件名 File的directory函数
		@o_error = "error! path is not directory" if !File.directory?@path
		
	end
	def directory?
		if @o_error == "error! path is not directory"
			p @o_error
		end
	end
	
	def obtain_path(file_path = @path)
		#p file_path
		if File.directory?(file_path)
		
			Dir.foreach(file_path) do |file|
				#.是当前目录 ..表示上一级目录
				if file != "." and file != ".."
					#p "123456"
					obtain_path(file_path + "/" + file)
				end
			end
		else
			# File.extname("foo/foo.tar.gz")  # => ".gz"
			if File.extname(file_path) == @extension and File.basename(file_path,@extension) =~ /#{@file_name}/i
				@target_file_path << File.expand_path(file_path) ;
			end
		end
	end#end def obtain_path
	
	def get_data()
		obtain_path(@path)
		return @target_file_path ;
	end
	
end




