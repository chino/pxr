require "vector"
class Quat < Vector
	attr_accessor :w
	def initialize x,y,z,w
		super x,y,z
		@w = w
	end
	def length
		Math.sqrt @x**2 + @y**2 + @z**2 + @w**2
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
