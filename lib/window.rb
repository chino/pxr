require "mouse"
class Window
	attr_writer :display, :keyboard
	attr_reader :title, :w, :h, :depth
	def initialize title="Window", w=640, h=480, fullscreen=false, depth=32

		@title, @w, @h, @depth = title, w, h, depth

		SDL.init(SDL::INIT_VIDEO)
		SDL.setGLAttr(SDL::GL_DOUBLEBUFFER,1)

		flags = SDL::OPENGL
		flags |= SDL::FULLSCREEN if fullscreen
	
		SDL.setVideoMode(@w,@h,@depth,flags)

		reshape @w,@h

		@display = Proc.new{}
		@keyboard = Proc.new{}

		GL.Enable(GL::DEPTH_TEST)
		GL.DepthFunc(GL::LESS) 
		GL.ShadeModel(GL::SMOOTH)
		GL.Disable(GL::CULL_FACE)
		GL.CullFace(GL::BACK)
		GL.FrontFace(GL::CW)
		GL.Disable(GL::LIGHTING)
		GL.Hint(GL::PERSPECTIVE_CORRECTION_HINT, GL::NICEST)
		#GL.PolygonMode(GL::FRONT, GL::LINE)
		#GL.PolygonMode(GL::BACK, GL::LINE)

		@last_frame = 0
		@frames = 0
		@fps = 0
		@fov = 70.0
		@x, @y = 0, 0

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
		GL.MatrixMode(GL::MODELVIEW)
	end
	def run
		while true
			handle_events
			render
		end
	end
	def mouse_grab bool=true
		@grabbed = bool
		bool ?  SDL::Mouse.hide : SDL::Mouse.show
	end
	def mouse_grab_swap
		mouse_grab !@grabbed
	end
	def mouse_get
		return [0,0] unless @grabbed
		x, y = @x, @y
		@x, @y = 0, 0
		SDL::Mouse.warp @w/2, @h/2
		[x, y]
	end
	def mouse_set x,y
                @x = x - (@w/2)
                @y = y - (@h/2)
	end
	def handle_events
		while event = SDL::Event2.poll
			case event
			when SDL::Event2::Active
				mouse_grab event.gain
			when SDL::Event2::KeyDown
				if event.sym == 27
					SDL.quit 
				elsif event.sym.chr == "`"
					mouse_grab_swap
				else
					@keyboard.call event.sym, true
				end
			when SDL::Event2::KeyUp
				@keyboard.call event.sym, false
			when SDL::Event2::MouseMotion
				mouse_set event.x, event.y
			when SDL::Event2::MouseButtonDown
				puts "mouse button down #{event.button}"
			when SDL::Event2::MouseButtonUp
				puts "mouse button up #{event.button}"
			end
		end
	end
	def render 
		GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
		@display.call
		GL.Flush
		SDL.GLSwapBuffers
		SDL::WM.setCaption "#{@title} - FPS: #{fps}", 'icon'
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
