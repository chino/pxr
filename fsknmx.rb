class BinReader
	def initialize file
		@contents = File.read file
	end
	def read_chars count
		@contents.slice!(0,count).unpack("a#{count}")[0]
	end
	def read_str
		str = @contents.unpack("Z*")[0]
		@contents.slice!(0,str.length+1)
		str
	end
	def read_int
		@contents.slice!(0,4).unpack("v")[0]
	end
	def read_short
		@contents.slice!(0,2).unpack("S")[0]
	end
	def read_float
		@contents.slice!(0,4).unpack("e")[0]
	end
	def read_close
		@contents = nil
	end
end
class FsknMx < BinReader
	attr_accessor :file, :level, :magic, :version, :textures, :verts, :triangles
	def initialize file
		@file = file
		@level = File.basename file
		super file
		@magic = read_chars 4
		@version = read_int
		@textures = []
		read_short.times {
			@textures << read_str
		}
		@verts = []
		@triangles = []
		vert_offset = 0
		@groups = read_short
		@groups.times {|g|
			verts = 0	
			exelists = read_short
			exelists.times {|e|
				exec_type = read_int
				verts = read_short
				verts.times {|v|
					@verts << [ read_float, read_float, read_float ]
					reserved = read_int
					color = read_int
					specular = read_int
					tu = read_float
					tv = read_float
				}
				texture_groups = read_short
				texture_groups.times {|t|
					texture_type = read_short
					start_vert = read_short
					num_verts = read_short
					texture_number = read_short
					triangles = read_short
					triangles.times {|tr|
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
			vert_offset += verts
		}
		read_close
	end
	def dump
		puts "level: #{@file}"
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
	def dump_vert v
		x,y,z = v
		sprintf "(%f,%f,%f)", x, y, z
	end
end
