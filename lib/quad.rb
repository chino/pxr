require "model"
class Quad < Model
	include Mesh
	attr_accessor :pos, :orientation, :normal
	def initialize s
		@render_type = GL::QUADS
#		@render_type = GL::POLYGON
		@texture =  s[:texture]
		@pos = s[:pos] || Vector.new(0,0,0)
		@normal = s[:normal] || Vector.new(0,0,1)
		@orientation = @normal.quat.normalize
		@verts = []
		@primitives = []
		@scale = s[:scale] || 10
		rows=10
		cols=10
		cols.times do |x|
			rows.times do |y|
				add x*@scale, y*@scale
			end
		end
	end
	def add x,y
		l = @verts.length
		@primitives << { 
			:verts => [ l+0,l+1,l+2,l+3 ],
#			:verts => [ l+0,l+1,l+2 ],
#			:pos => @pos.to_a, # any position on plane
#			:normal => @normal.to_a,
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
