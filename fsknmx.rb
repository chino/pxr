class BinReader
	def open file
		@file = File.open file
	end
	def read count
		@file.read(count).to_s
	end
	def read_str
		str = ""
		while char = @file.read(1)
			break if char == "\0"
			str += char
		end
		str
	end
	def read_char
		read(1).unpack("C")[0]
	end
	def read_int
		read(4).unpack("v")[0]
	end
	def read_short
		read(2).unpack("S")[0]
	end
	def read_float
		read(4).unpack("e")[0]
	end
	def read_close
		@file.close
	end
end
class FsknMx < BinReader
	attr_accessor :level, :magic, :version, :textures, :verts, :triangles
	def initialize file
		@level = File.basename file
		open file
		@magic = read 4
		@version = read_int
		@textures = []
		read_short.times { @textures << read_str }
		@verts = []
		@triangles = []
		vert_offset = 0
		@groups = read_short
		@groups.times {|g|
			group_verts = 0
			read_short.times {|e|
				exec_type = read_int
				read_short.times {|v|
					vert = [ read_float, read_float, read_float ]
					reserved = read_int
					blue, green, red, alpha = read_char, read_char, read_char, read_char 
					specular, tu, tv = read_int, read_float, read_float
					group_verts += 1
					@verts << {
						:vector => vert,
						:rgba => [red,green,blue,alpha]
					}
				}
				read_short.times {|t|
					texture_type, start_vert, nverts, texture = read_short, read_short, read_short, read_short
					read_short.times {|tr|
						@triangles << [
							read_short + vert_offset,
							read_short + vert_offset,
							read_short + vert_offset
						]
						pad16 = read_short
						normal = [ read_float, read_float, read_float ]
					}
				}
			}
			vert_offset += group_verts
		}
		read_close
	end
	def dump
		puts "level: #{@level}"
		puts "magic: #{@magic}"
		puts "version: #{@version}"
		puts "textures: (#{@textures.length}): #{@textures.join(", ")}"
		puts "groups: #{@groups}"
		puts "verts: #{@verts.length}"
		puts "triangles: #{@triangles.length}"
		@triangles.each_with_index do |t,i|
			puts "\t#{i}: #{dump_tri t}"
		end
	end
	def dump_tri tri
		tri.map{|indice| dump_vert @verts[indice]}.join ", "
	end
	def dump_vert vert
		x,y,z = vert[:vector]
		sprintf "(%f,%f,%f)", x, y, z
	end
end
