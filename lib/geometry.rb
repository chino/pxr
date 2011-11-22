module Geometry
	module Triangle
		@@third = 1.0/3.0
		def self.centroid v0, v1, v2
			(v0+v1+v2) * @@third
		end
		def self.normal v0, v1, v2
			(v1-v0).cross(v2-v1).normalize.to_a
		end
	end
end
