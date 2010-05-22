require 'mesh'
class Point
	include Mesh
	attr_writer :size
	def initialize *args
		super *args
		@render_type = GL::POINTS
		@size = 1.0
		@verts = []
		@primitives = []
		@verts << { :vector => [0,0,0], :rgba => [255,255,255,255] }
		@primitives << { :texture => nil, :verts => [0] }
		@poisition = Vector.new
		@orientation = Quat.new
	end
end
