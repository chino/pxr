class Model
	attr_accessor :mesh, :body
	def initialize file, body=nil

		@body = nil

		## init mesh
		path = "#{$models}/#{file}"
		ext = path.split('.').last.downcase
		loader = $loaders[ext]
		throw "unknown mesh loader for #{ext}" if loader.nil?
		@mesh = loader.new path

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
end
