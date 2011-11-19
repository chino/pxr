require "model"
class Line < Model
	include Mesh
	def initialize s={}	
		@pos = s[:pos] || Vector.new
		@orientation = Quat.new
		@render_type = GL::LINES
		@verts = []
		@primitives = []
		s[:lines].each do |start,stop,color,texture|
			color ||= [255,255,255,255]
			@verts << { :vector => start, :rgba => color }
			@verts << { :vector => stop, :rgba => color }
			@primitives << {
				:texture => texture, 
				:verts => [
					@verts.length-2,
					@verts.length-1
				]
			}
		end
		scale s[:scale] if s[:scale]
	end
end
