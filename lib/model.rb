class Model
	@@dir = "data/models"
	@@models = {}
	attr_accessor :model, :body, :scale, :pos, :orientation
	def pos
		@body.nil? ? @pos||=Vector.new : @body.pos
	end
	def orientation
		@body.nil? ? @orientation||=Vector.new(0,1,0).quat : @body.orientation
	end
	def initialize file="ball1.mx", body=nil
		@body = body
		@path = "#{@@dir}/#{file}"
		ext = @path.split('.').last.downcase
		@model ||= @@models[@path]
		return unless @model.nil?
		loader = $loaders[ext]
		throw "cannot determine model loader" if loader.nil?
		@model = loader.new @path
		@attachments = []
# TODO - need to scale mesh instead of using glScale
		@scale = Vector.new 1, 1, 1
	end
	def draw mode=:both # :opaque , :trans
		@model.draw mode
		# each transformation starts from the parent objects perspective
		# you can attach models to child objects if you want to chain down
		@attachments.each do |attachment|
			GL.PushMatrix
			attachment.load_matrix
			attachment.draw mode
			GL.PopMatrix
		end
	end
	def attach model
		@attachments << model
	end
	def detach model
		@attachments.delete model
	end
	def load_matrix
		up = orientation.vector :up
		forward = orientation.vector :forward
		right = orientation.vector :right
		GL.MatrixMode(GL::MODELVIEW)
		GL.MultMatrix [
			right.x, right.y, right.z, 0.0,
			up.x, up.y, up.z, 0.0,
			forward.x, forward.y, forward.z, 0.0,
			pos.x, pos.y, -pos.z, 1.0
		]
		GL.Scale( @scale.x, @scale.y, @scale.z )
	end
end
