class Render
	attr_accessor :models, :fps, :width, :height, :depth, :fov
	def initialize s
		@models = []
		@fps = 0
		@frames = 0
		@last_frame = 0
		@depth = s[:depth] || 32
		@fov = s[:fov].to_f || 70.0
		@fullscreen = s[:fullscreen]
		@width = s[:width].to_f
		@height = s[:height].to_f
		SDL.init(SDL::INIT_VIDEO)
		SDL.setGLAttr(SDL::GL_DOUBLEBUFFER,1)
		flags = SDL::OPENGL
		flags |= SDL::FULLSCREEN if @fullscreen
		SDL.setVideoMode( @width, @height, @depth, flags )
		reshape( @width, @height )
		GL.Enable(GL::DEPTH_TEST)
		GL.DepthFunc(GL::LESS) 
		GL.ShadeModel(GL::SMOOTH)
		GL.Disable(GL::CULL_FACE)
		GL.CullFace(GL::BACK)
		GL.FrontFace(GL::CW)
		GL.Disable(GL::LIGHTING)
		GL.Hint(GL::PERSPECTIVE_CORRECTION_HINT, GL::NICEST)
	end
	def reshape width=640, height=480
		@width = width.to_f
		@height = height.to_f
		GL.Viewport(0, 0, @width, @height);
		GL.MatrixMode(GL::PROJECTION)
		GL.LoadIdentity
		aspect = @width / @height
		GLU.Perspective(@fov, aspect, 10.0, 100000.0)
		GL.MatrixMode(GL::MODELVIEW)
	end
	def wireframe
		GL.PolygonMode(GL::FRONT, GL::LINE)
		GL.PolygonMode(GL::BACK, GL::LINE)
	end
	def draw pos, orientation
		GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
		look_at( pos, orientation )
		draw_models( :opaque )
		draw_models( :trans )
		GL.Flush
		SDL.GLSwapBuffers
		update_fps
	end
	def draw_models mode=:opaque
		set_trans if mode == :trans
		@models.each do |m|
			GL.PushMatrix
			load_matrix( m.pos, m.orientation )
			m.draw( mode )
# TODO - should make this routine recurisve so attachments can have attachments
			m.attachments.each do |a|
				GL.PushMatrix
				load_matrix( a.pos, a.orientation )
				a.draw( mode )
				GL.PopMatrix
			end if m.respond_to? :attachments
			GL.PopMatrix
		end
		unset_trans if mode == :trans
	end
	def look_at pos, orientation
		up = orientation.vector :up
		forward = orientation.vector :forward
		GL.MatrixMode(GL::MODELVIEW)
		GL.LoadIdentity
		gluLookAt(
			pos.x,pos.y,-pos.z,
			pos.x+forward.x,pos.y+forward.y,-pos.z-forward.z,
			up.x,up.y,-up.z
		)		
	end
	def load_matrix pos, orientation
		up = orientation.vector :up
		forward = orientation.vector :forward
		right = orientation.vector :right
		GL.MatrixMode(GL::MODELVIEW)
		GL.MultMatrix [
			right.x, right.y, right.z, 0.0,
			up.x, up.y, up.z, 0.0,
			forward.x, forward.y, forward.z, 0.0,
			pos.x, pos.y, -pos.z, 1.0
		]
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
	def update_fps
		@frames += 1
		t = Time.now
		seconds = (t - @last_frame).to_i
		return @fps unless seconds >= 1
		@last_frame = t
		@fps = @frames / seconds
		@frames = 0
		@fps
	end
end
