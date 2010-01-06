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
			GL.Begin @render_type
			primitive.each do |index|
				GL.Color4ubv @verts[index][:rgba]
				GL.Vertex3fv @verts[index][:vector]
			end
			GL.End
		end
	end
end
