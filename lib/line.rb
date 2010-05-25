require "model"
class Line < Model
	include Mesh
	def initialize lines=[]
		@render_type = GL::LINES
		@verts = []
		@primitives = []
		lines.each do |start,stop,color,texture|
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
	end
end
