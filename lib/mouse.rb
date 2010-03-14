class Mouse
class << self
	@@window = nil
	def window=(x); @@window=x; end
	@@grabbed = false
	def grab_swap
		grab !@@grabbed
	end
	def grab bool=true
		@@grabbed = bool
		if bool
			hide
		else
			show
		end
	end
	def release
		grab false
	end
	@@x = 0
	@@y = 0
	def input x, y
		@@x = x - (@@window.w/2)
		@@y = y - (@@window.h/2)
	end
	def get
		return [0,0] unless @@grabbed
		x, y = @@x, @@y
		center
		[x, y]
	end
	def center
		@@x, @@y = 0, 0
		SDL::Mouse.warp @@window.w/2, @@window.h/2
	end
	def hide
		SDL::Mouse.hide
	end
	def show
		SDL::Mouse.show
	end
end
end
