class Input
	attr_writer :display, :keyboard, :mouse_button
	def initialize s
		SDL::Event.enable_unicode
		mouse_grab
		@keyboard = Proc.new{}
		@mouse_button = Proc.new{}
		@x, @y = 0, 0
		@listeners = []
		@w,@h = s[:width], s[:height]
	end
	def on_poll listener
		@listeners << listener
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
		[x,y]
	end
	def mouse_set x,y
                @x = x - (@w/2)
                @y = y - (@h/2)
	end
	def poll
		while event = SDL::Event2.poll
			case event
			when SDL::Event2::Active
				mouse_grab event.gain
			when SDL::Event2::KeyDown
				if event.sym == 27
					SDL.quit 
					exit 0
				end
				begin
					if event.sym.chr == "`"
						mouse_grab_swap
						return
					end
				rescue
				end
				@keyboard.call event.sym, event.unicode, true
			when SDL::Event2::KeyUp
				@keyboard.call event.sym, event.unicode, false
			when SDL::Event2::MouseMotion
				mouse_set event.x, event.y
			when SDL::Event2::MouseButtonDown
				@mouse_button.call event.button, true
			when SDL::Event2::MouseButtonUp
				@mouse_button.call event.button, false
			end
		end
		call_listeners
	end
	def call_listeners
		@listeners.each do |listener|
			listener.call
		end
	end
end
