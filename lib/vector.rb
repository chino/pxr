class Vector
	attr_accessor :x, :y, :z
	def initialize x=0,y=0,z=0
		@x,@y,@z = x,y,z
	end
	def quat
		Quat.new @x, @y, @z, 0
	end
	def + p2
		Vector.new(
			@x + p2.x,
			@y + p2.y,
			@z + p2.z
		)
	end
	def serialize repr=:full
		case repr
		when :full
			# Exact representation, 12 bytes: x,y,z as floats.
			[ @x, @y, -@z ].pack "e3"
		when :short
			# Short representation, 6 bytes: x,y,z as shorts (16 bits each).
			# Components may not be greater than 1.0.
			([ @x, @y, -@z ].map { |x| (x*32767.999).to_i }).pack "v3"
		end
	end
	def unserialize! data, repr=:full
		case repr
		when :full
			@x, @y, @z = data.unpack "e3"
		when :short
			@x, @y, @z = data.unpack("v3").map { |x| x/32767.999 }
		end
	end
end
