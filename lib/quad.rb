require "model"
class Quad < Model
	include Mesh
	attr_accessor :normal, :pairs, :collision
	def initialize *args
		super *args
		@collision = :mesh
		@render_type = GL::QUADS
#		@render_type = GL::POLYGON
		@texture = 'data/images/yelo.png'
		@normal = [0,0,1]
		@verts = []
		@primitives = []
		rows=10
		cols=10
		cols.times do |x|
			rows.times do |y|
				add x, y
			end
		end
	end
	def add x,y
		l = @verts.length
		@primitives << { 
			:verts => [ l+0,l+1,l+2,l+3 ],
#			:verts => [ l+0,l+1,l+2 ],
			:pos => @pos, # one of poly verts for plane position
			:normal => @normal,
			:texture => @texture,
		}
		@verts << { :vector => [x,y,0], :tu => 0, :tv => 0 }
		@verts << { :vector => [x,y,0], :tu => 1, :tv => 0 }
		@verts << { :vector => [x,y,0], :tu => 1, :tv => 1 }
		@verts << { :vector => [x,y,0], :tu => 0, :tv => 1 }
	end
	def make_dl
	end
end
