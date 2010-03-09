require "mesh"
require "image"
require "binreader"
class FsknMx
	include Mesh
	include BinReader
	attr_reader :textures
	def initialize file
		@render_type = GL::POLYGON
		@level = File.basename file
		open file
		@magic = read 4
		@version = read_int
		@textures = []
		read_short.times { 
			path = "data/images/" + File.basename(read_str).sub(/\..*/,".png").downcase 
			Image.get path, true # load image if exists and allow color key
			@textures << path
		}
		@verts = []
		@primitives = []
		vert_offset = 0
		@groups = read_short
		@groups.times {|g|
			read_short.times {|e|
				exec_verts = 0
				exec_size = read_short
				exec_type = read_short
				has_transparencies = exec_type & 0x001 == 1
				read_short.times {|v|
					vert = [ read_float, read_float, read_float ]
					reserved = read_int
					blue, green, red, alpha = read_char, read_char, read_char, read_char 
					specular, tu, tv = read_int, read_float, read_float
					exec_verts += 1
					@verts << {
						:vector => vert,
						:rgba => [red,green,blue,alpha],
						:tu => tu,
						:tv => tv,
						:transparencies => has_transparencies
					}
				}
				read_short.times {|t|
					texture_type, start_vert, nverts, texture = read_short, read_short, read_short, read_short
					read_short.times {|tr|
						v = [
							read_short + vert_offset,
							read_short + vert_offset,
							read_short + vert_offset
						]
						pad16 = read_short
						normal = [ read_float, read_float, read_float ]
						@primitives << {
							:texture => @textures[texture],
							:verts => v,
							:normal => normal,
							:transparencies => has_transparencies
						}
					}
				}
				vert_offset += exec_verts
			}
		}
		read_close
		make_dl
	end
	def dump
		puts "level: #{@level}"
		puts "magic: #{@magic}"
		puts "version: #{@version}"
		puts "textures: (#{@textures.length}): #{@textures.join(", ")}"
		puts "groups: #{@groups}"
		puts "verts: #{@verts.length}"
		puts "triangles: #{@primitives.length}"
		@primitives.each_with_index do |t,i|
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
