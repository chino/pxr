require "model"
class Triangle < Model
	include Mesh
	def initialize s={}	
		@render_type = GL::POLYGON
		@body = s[:body]
		@verts = s[:verts]
		@centroid = Geometry::Triangle.centroid(
			Vector.new(@verts[0][:vector]),
			Vector.new(@verts[1][:vector]),
			Vector.new(@verts[2][:vector])
		)
		@normal = Geometry::Triangle.normal(
			Vector.new(@verts[0][:vector]),
			Vector.new(@verts[1][:vector]),
			Vector.new(@verts[2][:vector])
		)
		@primitives = [{
			:texture => s[:texture], 
			:verts => [ 0, 1, 2 ],
			:pos => @centroid,
			:radius => Mesh.compute_radius(@centroid,@verts),
			:normal => @normal,
			:transparencies => s[:transparencies]
		}]
	end
end
