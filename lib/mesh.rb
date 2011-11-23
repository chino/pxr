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
		return self unless @transparencies
		dl_trans = GL.GenLists(1)
		GL.NewList(dl_trans, GL::COMPILE)
		draw_trans
		GL.EndList
		@dl_trans = dl_trans
		self
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
		draw_trans if @transparencies and (mode==:both or mode==:trans)
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
			GL.Color4ubv vert[:rgba] || [255,255,255,255]
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
		# support scalar
		v = Vector.new(v,v,v) unless v.respond_to? :x
		@verts.each do |vert|
			vert[:vector][0] *= v.x
			vert[:vector][1] *= v.y
			vert[:vector][2] *= v.z if vert[:vector][2]
		end
		remake_dl
	end
	def radius
		@radius ||= compute_radius
	end
	def compute_radius
		@radius = Mesh.compute_radius(
			Vector.new,
			@verts 
		)
	end
	def self.compute_radius center, verts
		biggest = 0
		verts.each do |vert|
			v = Vector.new(vert[:vector])
			r = (center - v).length2
			biggest = r if r > biggest
		end
		radius = Math.sqrt(biggest)
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
			@normal_rendering = Line.new({ :lines => lines })
			@normal_rendering.make_dl
		end
		@normal_rendering
	end
	# returns count of expanded verts
	def number_of_verts
		@number_of_verts ||= begin
			size = 0
			@primitives.each do |primitive|
				primitive[:verts].each do |index|
					vert = @verts[index]
					size += vert[:vector].length
				end
			end
			size
		end
	end
	# returns an array of expanded verts
	def to_verts_array a=[]
		@primitives.each do |p|
			p[:verts].each do |index|
				a += @verts[index][:vector]
			end
		end
		a
	end
	# returns the verts list only as an array
	def to_indexed_verts_array a=[]
		@verts.each do |v|
			a += v[:vector]
		end
		a
	end
	# returns the index list only as an array
	def to_index_array a=[]
		@primitives.each do |p|
			a += p[:verts]
		end
		a
	end
end
