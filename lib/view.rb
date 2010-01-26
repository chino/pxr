class View
	attr_accessor :pos, :orientation, :scale
	def initialize *args
		@pos = Vector.new 0, 0, 0
		@orientation = Quat.new(0, 0, 0, 1).normalize
		@scale = Vector.new 1, 1, 1
	end
	# vector { x=right-left, y=up-down, z=forward-back }
	def move vector
		# translate vector by our orientation and add it to the position
		@pos += @orientation.vector vector
	end
	def rotate *args
		@orientation.rotate! *args
	end
	def place_camera
		up = @orientation.vector :up
		forward = @orientation.vector :forward
		GL.MatrixMode(GL::MODELVIEW)
		GL.LoadIdentity
		gluLookAt(
			@pos.x,@pos.y,-@pos.z,
			@pos.x+forward.x,@pos.y+forward.y,-@pos.z-forward.z,
			up.x,up.y,-up.z
		)
		GL.Scale(1,1,-1)
	end
	def load_matrix
		up = @orientation.vector :up
		forward = @orientation.vector :forward
		right = @orientation.vector :right
		GL.MatrixMode(GL::MODELVIEW)
		GL.MultMatrix [
			right.x, right.y, right.z, 0.0,
			up.x, up.y, up.z, 0.0,
			forward.x, forward.y, forward.z, 0.0,
			@pos.x, @pos.y, -@pos.z, 1.0
		]
		GL.Scale( @scale.x, @scale.y, @scale.z )
	end
end
