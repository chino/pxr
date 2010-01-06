class Mouse
class << self
	@@x = 0
	@@y = 0
	@@z = 0
	@@last_x = 0
	@@last_y = 0
	@@last_z = 0
	def input x, y
		x_diff = x - @@last_x
		y_diff = y - @@last_y
		@@last_x = x
		@@last_y = y
		@@x = x_diff
		@@y = y_diff
	end
	def get
		x, y = @@x, @@y
		@@x, @@y = 0, 0
		[x, y]
	end
end
end
