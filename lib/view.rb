class View
	attr_accessor :pos, :orientation
	def initialize *args
		@pos = Vector.new 0, 0, 0
		@orientation = Quat.new(0, 0, 1, 1).normalize
	end
	def rotate yaw=0, pitch=0, roll=0
		# create 3 quats for pitch, yaw, roll
		# and multiply those together to form a rotation quat
		# then apply it to the current quat to update it
 
		piover180 = Math::PI / 180.0

		p = pitch * piover180 / 2.0;
		y = yaw * piover180 / 2.0;
		r = roll * piover180 / 2.0;
 
		sinp = Math.sin(p);
		siny = Math.sin(y);
		sinr = Math.sin(r);
		cosp = Math.cos(p);
		cosy = Math.cos(y);
		cosr = Math.cos(r);
 
		@orientation = @orientation.normalize * Quat.new(
			sinr * cosp * cosy - cosr * sinp * siny,
			cosr * sinp * cosy + sinr * cosp * siny,
			cosr * cosp * siny - sinr * sinp * cosy,
			cosr * cosp * cosy + sinr * sinp * siny
		).normalize
	end
end
