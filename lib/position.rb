# represents a 3d position
class Position < Vector
	def + p2
		Position.new(
			@x + p2.x,
			@y + p2.y,
			@z + p2.z
		)
	end
end
