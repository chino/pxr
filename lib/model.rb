class Model
	attr_accessor :mesh, :body, :debug
	def initialize s

		@pos = s[:pos] unless s[:pos].nil?
		@orientation = s[:orientation] unless s[:orientation].nil?

		@debug = s[:debug] || false
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
		@body.radius = @mesh.radius unless !@body.respond_to?(:radius) or @body.nil?

	end
	def pos
		@body.nil? ? 
			@pos ||= Vector.new :
			@body.pos
	end
	def orientation
		if @body.nil? or not @body.respond_to?(:orientation)
			@orientation ||= Vector.new(0,1,0).quat 
		else
			@body.orientation
		end
	end
	def radius
		@mesh.radius
	end
	def draw *args
		$debug = true if @debug
		@mesh.draw *args
		$debug = false if @debug
	end
	def attachments
		@mesh.attachments
	end
end
