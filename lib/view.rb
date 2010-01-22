require 'quat'
require 'vector'
class View
	attr_accessor :pos, :orientation
	def initialize *args
		@pos = Vector.new 0, 0, 0
		@orientation = Quat.new(0, 0, 0, 1).normalize
	end
	def rotate yaw=0, pitch=0, roll=0
		# create 3 quats for pitch, yaw, roll
		# and multiply those together to form a rotation quat
		# then apply it to the current quat to update it
 		sy, sp, sr = [yaw, pitch, roll].map { |x| Math.sin(x*Math::PI/360) }
		cy, cp, cr = [yaw, pitch, roll].map { |x| Math.cos(x*Math::PI/360) }
		@orientation *= Quat.new(
			cr*sp*cy + sr*cp*sy,
			cr*cp*sy - sr*sp*cy,
			sr*cp*cy - cr*sp*sy,
			cr*cp*cy + sr*sp*sy
		).normalize
	end
	def load_matrix
		up = @orientation * Quat.new(0, 1, 0, 0) * @orientation.conjugate
		#puts "up = " + up.inspect

		forward = @orientation * Quat.new(0, 0, 1, 0) * @orientation.conjugate
		#puts "forward = " + forward.inspect

		GL.MatrixMode(GL::MODELVIEW)
		GL.LoadIdentity
		gluLookAt(
			@pos.x,@pos.y,-@pos.z,
			@pos.x+forward.x,@pos.y+forward.y,-@pos.z-forward.z,
			up.x,up.y,-up.z
		)
		GL.Scale(1,1,-1)

		#puts GL.GetFloatv(GL::MODELVIEW_MATRIX).inspect
	end
end
