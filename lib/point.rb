require 'mesh'
class Point < Model
	include Mesh
	attr_writer :size
	def initialize s
		@scale = Vector.new 1,1,1
		@body = nil
		@pos = Vector.new
		@orientation = Quat.new
		@render_type = GL::POINTS
		@size = s[:size] || 1.0
		@verts = []
		@primitives = []
		s[:points].each do |pos,color,texture|
			color ||= [255,255,255,255]
			@verts << { :vector => pos, :rgba => color }
			@primitives << { :texture => texture, :verts => [
				@verts.length - 1
			]}
		end
	end
end
