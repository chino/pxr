require "model"
class Plane < Model
	include Mesh
	attr_accessor :pos, :orientation
	def initialize s={}
		@render_type = GL::QUADS
		@pos = s[:pos] || Vector.new()
		normal = s[:normal] || Vector.new(0,0,-1)
		@orientation = Quat.from_vector( normal )
		c = s[:color] || [255,255,255,255]
		@primitives = [{ 
			:verts => [ 0,1,2,3 ],
			:normal => normal.to_a,
			:texture => s[:texture],
		}]
		x = y = -0.5
		@verts = [
			{ :vector => [ x,   y,   0 ], :tu => 0, :tv => 0, :rgba => c },
			{ :vector => [ x+1, y,   0 ], :tu => 1, :tv => 0, :rgba => c },
			{ :vector => [ x+1, y+1, 0 ], :tu => 1, :tv => 1, :rgba => c },
			{ :vector => [ x,   y+1, 0 ], :tu => 0, :tv => 1, :rgba => c }
		]
		scale s[:scale] if s[:scale]
		make_dl
	end
end
