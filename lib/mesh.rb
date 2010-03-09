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
		trans=[]
		@primitives.each do |primitive|
			if primitive[:transparencies]
				trans << primitive
				next
			end
			draw_primitive primitive
		end
		trans.each do |primitive|
			draw_primitive primitive
		end
	end
	def set_trans
		GL.DepthMask(GL::FALSE)
		GL.Enable(GL::BLEND)
		GL.BlendFunc(GL::SRC_ALPHA,GL::ONE)
	end
	def unset_trans
		GL.DepthMask(GL::TRUE)
		GL.Disable(GL::BLEND)
	end
	def draw_primitive primitive
		set_trans if primitive[:transparencies]
		image = Image.get primitive[:texture]
		if !image.nil? and image.colorkey
			GL.Enable(GL::ALPHA_TEST)
			GL.AlphaFunc(GL::GREATER,(100.0/255.0))
		end
		image.bind if image
		GL.PointSize(@size) if @render_type == GL::POINTS and @size
		GL.Begin @render_type
		GL.Normal3fv primitive[:normal] if primitive[:normal]
		primitive[:verts].each do |index|
			vert = @verts[index]
			GL.Color4ubv vert[:rgba] if vert[:rgba]
			GL.TexCoord2f vert[:tu], vert[:tv] if vert[:tu] and vert[:tv]
			GL.Vertex3fv vert[:vector]
		end
		GL.End
		GL.Disable(GL::ALPHA_TEST) if !image.nil? and image.colorkey
		image.unbind if image
		unset_trans if primitive[:transparencies]
	end
end
