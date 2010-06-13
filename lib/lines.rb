class Lines
	include Mesh
	attr_accessor :pos, :orientation, :attachments
	def initialize s={}
		@pos = s[:pos] || Vector.new
		@orientation = Vector.new(0,1,0).quat
		@attachments = []
		@render_type = GL::LINES
		@verts = []
		@primitives = []
		@verts << { :vector => [0,0,0], :rgba => [255,255,255,255] }
		@verts << { :vector => [1,0,0], :rgba => [255,255,0,255] } # x = yellow
		@verts << { :vector => [-1,0,0], :rgba => [255,255,0,255] } # x = yellow
		@verts << { :vector => [0,1,0], :rgba => [255,0,255,255] } # y = purple
		@verts << { :vector => [0,-1,0], :rgba => [255,0,255,255] } # y = purple
		@verts << { :vector => [0,0,1], :rgba => [0,255,255,255] } # z = blue
		@verts << { :vector => [0,0,-1], :rgba => [0,255,255,255] } # z = blue
		@primitives << { :texture => nil, :verts => [0,1] }
		@primitives << { :texture => nil, :verts => [0,2] }
		@primitives << { :texture => nil, :verts => [0,3] }
		@primitives << { :texture => nil, :verts => [0,4] }
		@primitives << { :texture => nil, :verts => [0,5] }
		@primitives << { :texture => nil, :verts => [0,6] }
		scale s[:scale] if s[:scale]
	end
end
