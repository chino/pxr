class View
	attr_accessor :pos, :view, :up
	def initialize *args
		@pos = Quat.new 0, 0, 0, 0	# origin
		@view = Quat.new 0, 0, -1, 0	# look down -z
		@up = Quat.new 0, 1, 0, 0	# up is +y
	end
	def view_turn x, y
		if y
			rot = ((@view - @pos) * @up).normalize
			rot.x *= Math.sin y
			rot.y *= Math.sin y
			rot.z *= Math.sin y
			rot.w = Math.cos y
			rv = (rot * view) * rot.conjugate
			@view.x = rv.x
			@view.y = rv.y
			@view.z = rv.z
		end
	end
	def lookat
		GL.MatrixMode(GL::MODELVIEW)
		GL.LoadIdentity
		GL.Scale(1,1,-1)
		GLU.LookAt(
			@pos.x, @pos.y, @pos.z,
			@view.x, @view.y, @view.z,
			@up.x, @up.y, @up.z
		)
	end
end
