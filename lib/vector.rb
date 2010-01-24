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
end
