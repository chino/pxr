class View
	attr_accessor :pos, :orientation
	def initialize *args
		@pos = Position.new 0, 0, 0
		@orientation = Quat.new(0, 0, 0, 1).normalize
	end
	# vector { x=right-left, y=up-down, z=forward-back }
	def move vector
		# translate vector by our orientation and add it to the position
		@pos += @orientation.vector vector
	end
	def rotate *args
		@orientation.rotate! *args
	end
	def load_matrix
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
end
