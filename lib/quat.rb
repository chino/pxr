require "vector"
class Quat
	def self.directions; @@directions; end
	def self.from_vector direction
		identity = Vector.new(0,0,-1) # opengl looks down -z
		axis = identity.cross( direction )
		angle = Math::acos( identity.dot( direction ) )
		from_axis( axis, angle )
	end
	def self.from_axis vector, angle
		angle *= 0.5
		n = vector.normalize
		sin_angle = Math::sin(angle)
		x = n.x * sin_angle
		y = n.y * sin_angle
		z = n.z * sin_angle
		w = Math::cos(angle)
		Quat.new x,y,z,w
	end
	attr_accessor :x, :y, :z, :w
	def initialize x=0,y=0,z=0,w=1
		if x.respond_to? :each # array given
			@x = x[0]||0
			@y = x[1]||0
			@z = x[2]||0
			@w = x[3]||0
		else
			@x,@y,@z,@w = x,y,z,w
		end
	end
	def length
		Math.sqrt dot
	end
	def length2
		dot
	end
	def has_velocity?
		dot > 0.001 # so we don't test super small values
	end
	def dot q=self
		@x * q.x + @y * q.y + @z * q.z + @w * q.w
	end
	def normalize
		l = length
		return Quat.new unless l > 0
		Quat.new( @x / l, @y / l, @z / l, @w / l )
	end
# todo - this probably only needs the dot product to avoid the sqrt
	def normalized?
		not length > 1.00001
	end
	def conjugate
		Quat.new( -@x, -@y, -@z, @w )
	end
	def conjugate!
		@x = -@x
		@y = -@y
		@z = -@z
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
	# http://gpwiki.org/index.php/OpenGL:Tutorials:Using_Quaternions_to_represent_rotation#Quaternion_from_Euler_angles
	@@pi360 = Math::PI / 180 / 2
#	def rotate! yaw=0, pitch=0, roll=0
#		a = yaw.respond_to?(:x) ? yaw.to_a : [yaw,pitch,roll]
	def rotate! pitch=0, yaw=0, roll=0
		a = pitch.respond_to?(:x) ? pitch.to_a : [pitch,yaw,roll]
		# create 3 quats for pitch, yaw, roll
		# and multiply those together to form a rotation quat
		# then apply it to the current quat to update it
#		sy, sp, sr = a.map { |x| Math.sin(x*@@pi360) }
#		cy, cp, cr = a.map { |x| Math.cos(x*@@pi360) }
		sp, sy, sr = a.map { |x| Math.sin(x*@@pi360) }
		cp, cy, cr = a.map { |x| Math.cos(x*@@pi360) }
		result = normalize * Quat.new(
			cr*sp*cy + sr*cp*sy,
			cr*cp*sy - sr*sp*cy,
			sr*cp*cy - cr*sp*sy,
			cr*cp*cy + sr*sp*sy
		).normalize
		@x,@y,@z,@w = result.to_a
		self
	end
	def rotate *args
		dup.rotate!(*args)
	end
	@@directions = {
		:up => Vector.new(0,1,0),
		:down => Vector.new(0,-1,0),
		:forward => Vector.new(0,0,-1),
		:back => Vector.new(0,0,1),
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
