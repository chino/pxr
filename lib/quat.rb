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
		q = Quat.new( @x / l, @y / l, @z / l, @w / l )
		l = q.length
		puts "Length (#{l}) not unit after normalization: #{inspect}" if l > 1.00001
		q
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
end
