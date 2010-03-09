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
#			draw_primitive primitive
		end
		GL.DepthMask(GL::FALSE)
		GL.Enable(GL::BLEND)
		GL.BlendFunc(GL::SRC_ALPHA,GL::ONE)
		trans.each_with_index do |primitive,i|
puts "primitive: #{i}"
			draw_primitive primitive
		end
		GL.DepthMask(GL::TRUE)
		GL.Disable(GL::BLEND)
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
		primitive[:verts].each_with_index do |index,i|
			vert = @verts[index]
			GL.Color4ubv vert[:rgba] if vert[:rgba]
			GL.TexCoord2f vert[:tu], vert[:tv] if vert[:tu] and vert[:tv]
			GL.Vertex3fv vert[:vector].map{|x|x.to_i}
puts "\tvert: #{i} = #{vert[:vector].join(', ')}"
		end
		GL.End
		GL.Disable(GL::ALPHA_TEST) if !image.nil? and image.colorkey
		image.unbind if image
	end
end
