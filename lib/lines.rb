require "model"
class Lines < Model
	include Mesh
	def initialize *args
		super *args
		@render_type = GL::LINES
		@verts = []
		@primitives = []
		@verts << { :vector => [0,0,0], :rgba => [255,255,255,255] }
		@verts << { :vector => [10000,0,0], :rgba => [255,255,0,255] } # x = yellow
		@verts << { :vector => [-10000,0,0], :rgba => [255,255,0,255] } # x = yellow
		@verts << { :vector => [0,10000,0], :rgba => [255,0,255,255] } # y = purple
		@verts << { :vector => [0,-10000,0], :rgba => [255,0,255,255] } # y = purple
		@verts << { :vector => [0,0,10000], :rgba => [0,255,255,255] } # z = blue
		@verts << { :vector => [0,0,-10000], :rgba => [0,255,255,255] } # z = blue
		@primitives << { :texture => nil, :verts => [0,1] }
		@primitives << { :texture => nil, :verts => [0,2] }
		@primitives << { :texture => nil, :verts => [0,3] }
		@primitives << { :texture => nil, :verts => [0,4] }
		@primitives << { :texture => nil, :verts => [0,5] }
		@primitives << { :texture => nil, :verts => [0,6] }
	end
end
