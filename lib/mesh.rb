module Mesh
	attr_accessor :primitives, :verts
	def make_dl
		# opaque
		dl_opaque = GL.GenLists(1)
		GL.NewList(dl_opaque, GL::COMPILE)
		draw_opaque
		GL.EndList
		@dl_opaque = dl_opaque
		# trans
		dl_trans = GL.GenLists(1)
		GL.NewList(dl_trans, GL::COMPILE)
		draw_trans
		GL.EndList
		@dl_trans = dl_trans
	end
	def free_dl
		GL.DeleteLists(@dl_opaque, 1) unless @dl_opaque.nil?
		GL.DeleteLists(@dl_trans, 1) unless @dl_trans.nil?
	end
	def remake_dl
		free_dl
		make_dl
	end
	def draw mode=:both # :opaque, :trans
		draw_opaque if mode==:both or mode==:opaque
		draw_trans if mode==:both or mode==:trans
	end
	def draw_trans
		if @dl_trans then
			GL.CallList(@dl_trans)
			return
		end
		@primitives.each do |primitive|
			draw_primitive primitive if primitive[:transparencies]
		end
	end
	def draw_opaque
		if @dl_opaque then
			GL.CallList(@dl_opaque)
			return
		end
		@primitives.each do |primitive|
			draw_primitive primitive unless primitive[:transparencies]
		end
	end
	def draw_primitive primitive
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
			GL.Color4ubv vert[:rgba]||[255,255,255,255]
			GL.TexCoord2f vert[:tu], vert[:tv] if vert[:tu] and vert[:tv]
			GL.Vertex3fv vert[:vector]
		end
		GL.End
		GL.Disable(GL::ALPHA_TEST) if !image.nil? and image.colorkey
		image.unbind if image
	end
	def attach model
		@attachments = [] if @attachments.nil?
		@attachments << model
	end
	def detach model
		@attachments.delete model
	end
	def scale x,y,z
		@verts.each do |vert|
			vert[:vector] = [
				vert[:vector][0] * x,
				vert[:vector][1] * y,
				vert[:vector][2] * z
			]
		end
	end
end
