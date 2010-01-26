module Mesh
	attr_accessor :primitives, :verts
	def make_dl
		dl = GL.GenLists(1)
		GL.NewList(dl, GL::COMPILE)
		draw
		GL.EndList
		@dl = dl
	end
	def free_dl
		GL.DeleteLists(@dl, 1)
	end
	def draw
		if @dl then
			GL.CallList(@dl)
			return
		end
		@primitives.each do |primitive|
			Images.bind primitive[:texture]
			GL.Begin @render_type
			primitive[:verts].each do |index|
				vert = @verts[index]
				GL.Color4ubv vert[:rgba] if vert[:rgba]
				GL.TexCoord2f vert[:tu], vert[:tv] if vert[:tu] and vert[:tv]
				GL.Vertex3fv vert[:vector]
			end
			GL.End
			Images.unbind primitive[:texture]
		end
	end
end
