require "vector"
class Quat < Vector
	attr_accessor :w
	def initialize *args
		super args[0],args[1],args[2]
		@w = args[3] || 0
	end
	def length
		Math.sqrt self.dot(self)
	end
	def dot q
		@x * q.x + @y * q.y + @z * q.z + @w * q.w
	end
	def normalize
		d = length
		Quat.new( @x / d, @y / d, @z / d, @w / d )
	end
	def conjugate
		Quat.new( -@x, -@y, -@z )
	end
	def cross q
		Quat.new(
			@y * q.z - @z * q.y,
			@z * q.x - @x * q.z,
			@x * q.y - @y * q.x,
		)
	end
	def * q
		Quat.new(
			@w * q.x + @x * q.w + @y * q.z - @z * q.y,
			@w * q.y + @y * q.w + @z * q.x - @x * q.z,
			@w * q.z + @z * q.w + @x * q.y - @y * q.x,
			@w * q.w - @x * q.x - @y * q.y - @z * q.z
		)
	end
	def - q
		Quat.new( @x - q.x, @y - q.y, @z - q.z )
	end
end
