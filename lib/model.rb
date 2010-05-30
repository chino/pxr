class Model
	attr_accessor :mesh, :body
	def initialize s

		@body = s[:body]

		## init mesh
		path = "#{$models}/#{s[:file]}"
		ext = path.split('.').last.downcase
		loader = $loaders[ext]
		throw "unknown mesh loader for #{ext}" if loader.nil?
		@mesh = loader.new path

		## scale object
		@mesh.scale s[:scale] unless s[:scale].nil?

		## figure out radius
		@body.compute_radius( @mesh.verts ) unless @body.nil?

	end
	def pos
		@body.nil? ? 
			@pos ||= Vector.new :
			@body.pos
	end
	def orientation
		@body.nil? ? 
			@orientation ||= Vector.new(0,1,0).quat : 
			@body.orientation
	end
	def draw *args
		@mesh.draw *args
	end
	def attachments
		@mesh.attachments
	end
end
