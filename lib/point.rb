require 'mesh'
class Point < Model
	include Mesh
	attr_writer :size
	def initialize points=[]
		@scale = Vector.new 1,1,1
		@body = nil
		@pos = Vector.new
		@render_type = GL::POINTS
		@size = 1.0
		@verts = []
		@primitives = []
		points.each do |pos,color,texture|
			color ||= [255,255,255,255]
			@verts << { :vector => pos, :rgba => color }
			@primitives << { :texture => texture, :verts => [
				@verts.length - 1
			]}
		end
	end
end
