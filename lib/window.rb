require "mouse"
class Window
	attr_writer :display, :keyboard
	attr_reader :title, :w, :h
	def initialize title, w, h, &block
		@title, @w, @h = title, w, h
		@display = Proc.new{}
		@keyboard = Proc.new{}
		GLUT.Init([])
		GLUT.InitDisplayMode(GLUT::DOUBLE | GLUT::RGB | GLUT::DEPTH)
		GLUT.InitWindowSize(@w, @h)
		GLUT.CreateWindow(@title)
		GLUT.ReshapeFunc(Proc.new{|w,h| reshape w, h })
		GLUT.DisplayFunc(Proc.new{ render })
		# capture key presses
		GLUT.KeyboardFunc(Proc.new{|key,x,y| 
			#puts "key: #{key} pressed @ #{x},#{y}"
			@keyboard.call key,x,y,true
		})
		GLUT.KeyboardUpFunc(Proc.new{|key,x,y|
			#puts "key: #{key} released @ #{x},#{y}"
			exit 0 if key == 27 # escape key
			Mouse.grab_swap if key.chr == "`"
			@keyboard.call key,x,y,false
		})
		# mouse inputs
		Mouse.window = self
		GLUT.EntryFunc(Proc.new{|entered|
			Mouse.grab entered == 1
		})
		GLUT.PassiveMotionFunc(Proc.new{|x,y| Mouse.input x,y })
		GLUT.MouseFunc(Proc.new{|button,state,x,y| 
			puts "mouse button: #{button} "+
				"#{(state==GLUT::DOWN)?"pressed":"released"} @ #{x},#{y}"
		})
		# setup GL
		GL.Enable(GL::DEPTH_TEST)
		GL.DepthFunc(GL::LESS) 
		GL.ShadeModel(GL::SMOOTH)
		GL.Enable(GL::CULL_FACE)
		GL.CullFace(GL::BACK)
		GL.FrontFace(GL::CW)
		GL.Disable(GL::LIGHTING)
		GL.Hint(GL::PERSPECTIVE_CORRECTION_HINT, GL::NICEST)
		# wireframe mode
		#GL.PolygonMode(GL::FRONT, GL::LINE)
		#GL.PolygonMode(GL::BACK, GL::LINE)
		#
		reshape @w, @h
		#
		@last_frame = 0
		@frames = 0
		@fps = 0
		#
		@fov = 70.0
	end
	def aspect
		@w.to_f / @h.to_f
	end
	def reshape w, h
		@w, @h = w, h
		GL.Viewport(0, 0, @w, @h);
		GL.MatrixMode(GL::PROJECTION)
		GL.LoadIdentity
		GLU.Perspective(70.0, aspect, 10.0, 100000.0)
	end
	def render 
		GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
		@display.call
		GL.Flush
		GLUT.SwapBuffers
		GLUT.PostRedisplay
		GLUT.SetWindowTitle "#{@title} - FPS: #{fps}"
	end
	def run
		GLUT.MainLoop
	end
	def fps
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
