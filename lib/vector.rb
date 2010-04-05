class Vector
	attr_accessor :x, :y, :z
	def initialize x=0,y=0,z=0
		if x.respond_to? :each # array given
			@x = x[0]
			@y = x[1]
			@z = x[2]
		else
			@x=x
			@y=y
			@z=z
		end
	end
	def quat
		Quat.new @x, @y, @z, 0
	end
	def to_a
		[@x,@y,@z]
	end
	def to_s
		to_a.join(',')
	end
	def + p2
		if p2.respond_to? :x
			Vector.new( @x + p2.x, @y + p2.y, @z + p2.z )
		else
			Vector.new( @x + p2, @y + p2, @z + p2 )
		end
	end
	def - p2
		if p2.respond_to? :x
			Vector.new( @x - p2.x, @y - p2.y, @z - p2.z )
		else
			Vector.new( @x - p2, @y - p2, @z - p2  )
		end
	end
	def * i
		Vector.new(
			@x * i,
			@y * i,
			@z * i
		)
	end
	def dot q=self
		@x * q.x + @y * q.y + @z * q.z
	end
	def length
		Math.sqrt @x * @x + @y * @y + @z * @z
	end
	def cross v2
		Vector.new(
			@y*v2.z - @z*v2.y,
			@z*v2.x - @x*v2.z,
			@x*v2.y - @y*v2.x
		)
	end
	def normalize
		l = length; Vector.new( @x / l, @y / l, @z / l )
	end
	def serialize repr=:full
		case repr
		when :full
			# Exact representation, 12 bytes: x,y,z as floats.
			[ @x, @y, -@z ].pack "e3"
		when :short
			# Short representation, 6 bytes: x,y,z as shorts (16 bits each).
			# Components must be between -1.0 and 1.0 (inclusive).
			([ @x, @y, -@z ].map { |x| (x*32767.999).to_i + 32768 }).pack "v3"
		end
	end
	def unserialize! data, repr=:full
		case repr
		when :full
			@x, @y, @z = data.unpack "e3"
		when :short
			@x, @y, @z = data.unpack("v3").map { |x| (x-32768)/32767.999 }
		end
	end
end
