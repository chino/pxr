require 'quat'
class Camera
	attr_writer :ref, :pos, :up, :forward
	def initialize ref=nil
		@ref = ref
		update
	end
	def update
		return if @ref.nil?
		@pos = @ref.pos
		@up = Quat.new(0, 1, 0) * @ref.orientation
		@forward = Quat.new(0, 0, 1) * @ref.orientation
		GL.MatrixMode(GL::MODELVIEW)
		GL.LoadIdentity
		GL.Scale(1,1,-1)
		gluLookAt(
			@pos.x,@pos.y,@pos.z,
			@up.x,@up.y,@up.z,
			@forward.x,@forward.y,@forward.z
		)
	end
end
