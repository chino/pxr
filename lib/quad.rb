class Quad < View
	include Mesh
	def initialize *args
		super *args
		@render_type = GL::QUADS
#		@render_type = GL::POLYGON
		@scale = Vector.new 1000,1000,1000
#		@texture = 'data/images/water.jpg'
		@texture = 'data/images/yelo.png'
		@verts = []
		@primitives = []
		rows=100
		cols=100
		cols.times do |x|
			rows.times do |y|
				add x,y
			end
		end
	end
	def add x,y
		l = @verts.length
		@primitives << { :verts => [ l+0,l+1,l+2,l+3 ], :texture => @texture }
#		@primitives << { :verts => [ l+0,l+1,l+2 ] }
		@verts << { :vector => [x+0,y+0,0], :tu => 0, :tv => 0 }
		@verts << { :vector => [x+0,y+1,0], :tu => 1, :tv => 0 }
		@verts << { :vector => [x+1,y+1,0], :tu => 1, :tv => 1 }
		@verts << { :vector => [x+1,y+0,0], :tu => 0, :tv => 1 }
	end
	def make_dl
	end
end
