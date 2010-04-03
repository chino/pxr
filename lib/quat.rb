require "vector"
class Quat
	attr_accessor :x, :y, :z, :w
	def initialize x=0,y=0,z=0,w=0
		@x,@y,@z,@w = x,y,z,w
	end
	def length
		Math.sqrt dot
	end
	def dot q=self
		@x * q.x + @y * q.y + @z * q.z + @w * q.w
	end
	def normalize
		l = length
		Quat.new( @x / l, @y / l, @z / l, @w / l )
	end
	def normalized?
		not length > 1.00001
	end
	def conjugate
		Quat.new( -@x, -@y, -@z, @w )
	end
	def * q
		Quat.new(
			@w * q.x + @x * q.w + @y * q.z - @z * q.y,
			@w * q.y + @y * q.w + @z * q.x - @x * q.z,
			@w * q.z + @z * q.w + @x * q.y - @y * q.x,
			@w * q.w - @x * q.x - @y * q.y - @z * q.z
		)
	end
	def to_a
		[@x,@y,@z,@w]
	end
	def to_s
		to_a.join(',')
	end
	def rotate! yaw=0, pitch=0, roll=0
		# create 3 quats for pitch, yaw, roll
		# and multiply those together to form a rotation quat
		# then apply it to the current quat to update it
 		sy, sp, sr = [yaw, pitch, roll].map { |x| Math.sin(x*Math::PI/360) }
		cy, cp, cr = [yaw, pitch, roll].map { |x| Math.cos(x*Math::PI/360) }
		result = normalize * Quat.new(
			cr*sp*cy + sr*cp*sy,
			cr*cp*sy - sr*sp*cy,
			sr*cp*cy - cr*sp*sy,
			cr*cp*cy + sr*sp*sy
		).normalize
		@x,@y,@z,@w = result.to_a
	end
	def rotate *args
		dup.rotate!(*args)
	end
	@@directions = {
		:up => Vector.new(0,1,0),
		:down => Vector.new(0,-1,0),
		:forward => Vector.new(0,0,1),
		:back => Vector.new(0,0,-1),
		:right => Vector.new(1,0,0),
		:left => Vector.new(-1,0,0)
	}
	def vector direction
		d = (@@directions[direction] || direction).quat
		q = normalize * d * conjugate
		Vector.new( q.x, q.y, q.z )
	end
	def serialize repr=:full
		case repr
		when :full
			# Exact representation, 16 bytes: x,y,z,w as floats.
			[ @x, @y, @z, @w ].pack "e4"
		when :short
			# Short representation, 8 bytes: x,y,z,w as shorts (16 bits each).
			# Components must be between -1.0 and 1.0 (inclusive).
			([ @x, @y, @z, @w ].map { |x| (x*32767.999).to_i + 32768 }).pack "v4"
		end
	end
	def unserialize! data, repr=:full
		case repr
		when :full
			@x, @y, @z, @w = data.unpack "e4"
		when :short
			@x, @y, @z, @w = data.unpack("v4").map { |x| (x-32768)/32767.999 }
		end
	end
end
