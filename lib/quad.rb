class Quad < View
	include Mesh
	attr_accessor :normal
	def initialize *args
		super *args
		@render_type = GL::QUADS
#		@render_type = GL::POLYGON
		@scale = Vector.new 1000,1000,1000
#		@texture = 'data/images/water.jpg'
		@texture = 'data/images/yelo.png'
		@verts = []
		@primitives = []
		rows=10
		cols=10
		cols.times do |x|
			rows.times do |y|
				add x,y
			end
		end
		@normal = Vector.new(0,0,1)
		max_x = cols * @scale.x
		max_y = rows * @scale.y
		@pairs = [
			[Vector.new(0,0,0),Vector.new(max_x,0,0)],
			[Vector.new(max_x,0,0),Vector.new(max_x,max_y,0)],
			[Vector.new(max_x,max_y,0),Vector.new(0,max_y,0)],
			[Vector.new(0,max_y,0),Vector.new(0,0,0)]
		]
	end
	def within? point
		@pi2 ||= sprintf('%.14f',Math::PI * 2)
		radians = 0
		@pairs.each do |v1,v2|
			# vector from point to corner of polygon
			v1 = (v1 - point).normalize
			v2 = (v2 - point).normalize
			# angle between vectors
			radians += Math.acos( v1.dot(v2) )
		end
		radians = sprintf('%.14f',radians)
		radians == @pi2
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
