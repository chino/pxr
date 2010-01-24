class Mouse
class << self
	@@window = nil
	def window=(x); @@window=x; end
	@@x = 0
	@@y = 0
	def input x, y
		@@x = x - (@@window.w/2)
		@@y = y - (@@window.h/2)
	end
	def get
		x, y = @@x, @@y
		center
		[x, y]
	end
	def center
		@@x, @@y = 0, 0
		GLUT.WarpPointer @@window.w/2, @@window.h/2
	end
	def hide
		GLUT.SetCursor(GLUT::CURSOR_NONE);
	end
	def show
		GLUT.SetCursor(GLUT::CURSOR_INHERIT);
	end
end
end
