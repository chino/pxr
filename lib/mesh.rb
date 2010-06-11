module Mesh
	attr_accessor :primitives, :verts, :radius
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
		@dl_opaque = nil
		@dl_trans = nil
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
		primitive[:texture].bind unless primitive[:texture].nil?
		GL.PointSize(@size) if @render_type == GL::POINTS and @size
		GL.Begin @render_type
		GL.Normal3fv primitive[:normal] if primitive[:normal]
		primitive[:verts].each do |index|
			vert = @verts[index]
			GL.Color4ubv vert[:rgba]||[255,255,255,255]
			GL.TexCoord2f vert[:tu], vert[:tv] if vert[:tu] and vert[:tv]
			GL.Vertex3fv vert[:vector] if vert[:vector].length == 3
			GL.Vertex2fv vert[:vector] if vert[:vector].length == 2
		end
		GL.End
		primitive[:texture].unbind unless primitive[:texture].nil?
	end
	def attachments
		@attachments ||= []
	end
	def attach model
		attachments << model
	end
	def detach model
		attachments.delete model
	end
	def scale v
		@verts.each do |vert|
			vert[:vector] = [
				vert[:vector][0] * v.x,
				vert[:vector][1] * v.y,
				vert[:vector][2] * v.z
			]
		end
		remake_dl
	end
	def radius
		@radius ||= compute_radius
	end
	def compute_radius
		biggest = 0
		center = Vector.new
		@verts.each do |vert|
			v = Vector.new(vert[:vector])
			r = (center - v).length2
			biggest = r if r > biggest
		end
		@radius = Math.sqrt(biggest)
	end
	def normal_rendering
		if @normal_rendering.nil?
			lines = []
			@primitives.each do |primitive|
				next unless primitive[:normal]
				normal = Vector.new primitive[:normal]
				start  = Vector.new primitive[:pos]
				stop   = start + ( normal * 50 )
				lines << [start.to_a, stop.to_a]
			end
			@normal_rendering = Line.new(lines)
			@normal_rendering.make_dl
		end
		@normal_rendering
	end
end
