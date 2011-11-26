require "mesh"
require "model"
require "vector"
require "binreader"
class D1rdl
	include Mesh
	include BinReader
	def read_ushort
		# Read an unsigned 2-byte (short) integer
		read(2).unpack("S")[0]
	end
	def read_sshort
		# Read a signed 2-byte (short) integer
		read(2).unpack("s")[0]
	end
	def read_uchar
		# Read an unsigned char
		read(1).unpack("C")[0]
	end
	def read_sint
		# Read a signed integer
		read(4).unpack("i")[0]
	end
	def read_fix
		# Descent 1 and 2's fixed-point format
		read_sint / 65536.0
	end
	def initialize file
		@render_type = GL::POLYGON
		@level = File.basename file
		open file
		@magic = read 4
		@version = read_sint
		@offset = read_sint + 1
		@verts = []
		@primitives = []
		# Skip to mine geometry data
		read (@offset - 12)
		nverts, ncubes = read_short, read_short
		# Read vertex data
		nverts.times {
			@verts << {
				:vector => [read_fix, read_fix, read_fix],
				:rgba => [rand(255),rand(255),rand(255),rand(255)]
			}
		}
		# That was the easy part - now read the cubes section and
		# construct the polygon data from it.
		ncubes.times {
			sidemask = read_char
			# Count the number of sides (1-bits in sidemask)
			nsides = (0..5).count { |i| sidemask & (1<<i) != 0 }
			nsides.times { |i|
				if read_sshort < 0 then
					sidemask &= ~(1<<i)
				end
			}
			# Read the list of vertex indices for this cube
			cubeverts = []
			8.times {
				cubeverts << read_short
			}
			cvi = [           # cubeverts indices for each side:
				[3, 7, 6, 2], # right
				[4, 7, 3, 0], # top
				[4, 0, 1, 5], # left
				[6, 5, 1, 2], # bottom
				[7, 4, 5, 6], # back
				[0, 3, 2, 1]  # front
			]
			cvi.each_with_index { |vii,i|
				if sidemask & (1<<i) == 0 then
					# To compute the face normal...
					# ...first map from indices of indices to indices...
					vi = vii.map { |i|
						puts "Invalid vertex number (#{cubeverts[i]} >= #{nverts})" if cubeverts[i] >= nverts
						cubeverts[i]
					}
					# ...then from those indices to the real vertices...
					# ...converting them to Vectors in the process...
					v = vi.map { |i| Vector.new *@verts[i][:vector] }
					# ...then get the normal by taking the (normalized)
					# cross product of two of the face's edges - and
					# finally store everything.
					@primitives << {
						:texture => nil,
						:verts => vi,
						:normal => (v[1]-v[0]).cross(v[2]-v[1]).normalize.to_a
					}
				end
			}
			if sidemask & 64 != 0 then
				# Discard 4 bytes of `special' data
				read 4
			end
			# Discard lighting data
			read 2
			wallmask = read_char
			# Count the number of walls (1-bits in wallmask)
			6.times { |i|
				if wallmask & (1<<i) != 0 then
					# Read a byte of wall data and check for special
					# value.
					if read_uchar == 255 then
						wallmask &= ~(1<<i)
					end
				end
			}
			#nwalls = (0..6).count { |i| wallmask & (1<<i) != 0 }
			6.times { |i|
				if wallmask & (1<<i) != 0 or sidemask & (1<<i) == 0 then
					# Discard primary texture data...
					if read_sshort < 0 then
						# ...and secondary texture data if it's there
						read 2
					end
					# Discard UVL info
					read 24
				end
			}
		}
		read_close
		make_dl
	end
	def dump
		puts "level: #{@level}"
		puts "magic: #{@magic}"
		puts "version: #{@version}"
		puts "verts: #{@verts.length}"
		puts "primitives: #{@primitives.length}"
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
$loaders["rdl"] = D1rdl
