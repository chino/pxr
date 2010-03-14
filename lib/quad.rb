class Quad < View
	include Mesh
	def initialize *args
		super *args
		@render_type = GL::QUADS
		@scale = Vector.new 100,100,0
		@verts = []
		@primitives = []
		rows=20
		cols=20
		cols.times do |x|
			rows.times do |y|
				add x,y
			end
		end
	end
	def add x,y
		l = @verts.length
		@primitives << { :verts => [ l+0,l+1,l+2,l+3 ] }
		@verts << { :vector => [x+0,y+0,0] }
		@verts << { :vector => [x+0,y+1,0] }
		@verts << { :vector => [x+1,y+1,0] }
		@verts << { :vector => [x+1,y+0,0] }
	end
	def make_dl
	end
end