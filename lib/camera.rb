module Camera
	def self.place pos, orientation
		up = orientation.vector :up
		forward = orientation.vector :forward
		GL.MatrixMode(GL::MODELVIEW)
		GL.LoadIdentity
		gluLookAt(
			pos.x,pos.y,-pos.z,
			pos.x+forward.x,pos.y+forward.y,-pos.z-forward.z,
			up.x,up.y,-up.z
		)
	end
end
