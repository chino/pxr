module Mesh
	def draw
		@triangles.each do |poly|
			GL.Begin(GL::POLYGON)
			poly.each do |index|
				GL.Color4ubv @verts[index][:rgba]
				GL.Vertex3fv @verts[index][:vector]
			end
			GL.End
		end
	end
end
