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
	def dot q2
		@x * q2.x + @y * q2.y + @z * q2.z + @w * q2.w
	end
	def normalize
		d = length
		q = self.dup
		q.x /= d
		q.y /= d
		q.z /= d
		q.w /= d
		q
	end
	def conjugate
		q = self.dup
		q.x = -q.x
		q.y = -q.y
		q.z = -q.z
		q
	end
	def cross q2
		Quat.new(
			@y * q2.z - @z * q2.y, # x
			@z * q2.x - @x * q2.z, # y
			@x * q2.y - @y * q2.x, # z
			0
		)
	end
	def * q2
		q = self.dup
		q.x = q.w*q2.x + q.x*q2.w + q.y*q2.z - q.z*q2.y
		q.y = q.w*q2.y - q.x*q2.z + q.y*q2.w + q.z*q2.x
		q.z = q.w*q2.z + q.x*q2.y - q.y*q2.x + q.z*q2.w
		q.w = q.w*q2.w - q.x*q2.x - q.y*q2.y - q.z*q2.z
		q
	end
	def - q2
		q = self.dup
		q.x -= q2.x
		q.y -= q2.y
		q.z -= q2.z
		q
	end
end
