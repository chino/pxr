module Geometry
	module Triangle
		@@third = 1.0/3.0
		def self.centroid v0, v1, v2
			(v0+v1+v2) * @@third
		end
	end
end
