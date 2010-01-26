class Vector
	attr_accessor :x, :y, :z
	def initialize x=0,y=0,z=0
		@x,@y,@z = x,y,z
	end
	def quat
		Quat.new @x, @y, @z, 0
	end
	def to_a
		[@x,@y,@z]
	end
	def + p2
		Vector.new(
			@x + p2.x,
			@y + p2.y,
			@z + p2.z
		)
	end
	def - p2
		Vector.new(
			@x - p2.x,
			@y - p2.y,
			@z - p2.z
		)
	end
	def dot q=self
		@x * q.x + @y * q.y + @z * q.z
	end
	def length
		Math.sqrt dot
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
end
