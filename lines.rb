class Lines < View
	include Mesh
	def initialize *args
		super *args
		@render_type = GL::LINE
		@verts = []
		@primitives = []
		@verts << { :vector => [0,0,0], :rgba => [255,255,255,255] }
		@verts << { :vector => [100,0,0], :rgba => [255,255,0,255] } # x = yellow
		@verts << { :vector => [-100,0,0], :rgba => [255,255,0,255] } # x = yellow
		@verts << { :vector => [0,100,0], :rgba => [255,0,255,255] } # y = purple
		@verts << { :vector => [0,-100,0], :rgba => [255,0,255,255] } # y = purple
		@verts << { :vector => [0,0,100], :rgba => [0,255,255,255] } # z = blue
		@verts << { :vector => [0,0,-100], :rgba => [0,255,255,255] } # z = blue
		@primitives << [0,1]
		@primitives << [0,2]
		@primitives << [0,3]
		@primitives << [0,4]
		@primitives << [0,5]
		@primitives << [0,6]
	end
end
