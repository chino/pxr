class View
	attr_accessor :pos, :view, :up
	def initialize *args
		@pos = Quat.new 0, 0, 0, 0	# origin
		@view = Quat.new 0, 0, -1, 0	# look down -z
		@up = Quat.new 0, 1, 0, 0	# up is +y
	end
	def rotate x, y
		if y > 0
			rot = ((@view - @pos) * @up).normalize
			temp = rot.dup
			temp.x *= Math.sin y
			temp.y *= Math.sin y
			temp.z *= Math.sin y
			temp.w = Math.cos y
			rv = (temp * rot) * rot.conjugate
			@view.x = rv.x
			@view.y = rv.y
			@view.z = rv.z
		end
	end
	def goto
		puts "up.dot view != 0" if @up.dot(@view) != 0
		right = @up.cross @view
		GL.MatrixMode(GL::MODELVIEW)
		GL.LoadIdentity
		GL.Scale(1,1,-1)
		GL.MultMatrix [
			right.x, right.y, right.z, 0.0,
			@up.x, @up.y, @up.z, 0.0,
			@view.x, @view.y, @view.z, 0.0,
			@pos.x, @pos.y, @pos.z, 1.0
		]
	end
end
