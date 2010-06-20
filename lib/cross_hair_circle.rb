class CrossHairCircle
	attr_accessor :size
	def initialize size, screen
		@size = size
		@surface = SDL::Surface.new(
			SDL::SWSURFACE, @size*2, @size*2, screen
		).display_format
		@surface.draw_circle @size, @size, @size, [255,0,0]
		@id = GL.GenTextures(1)[0]
		bind
		GL.TexParameteri(GL::TEXTURE_2D,GL::TEXTURE_MIN_FILTER,GL::NEAREST)
		GL.TexParameteri(GL::TEXTURE_2D,GL::TEXTURE_MAG_FILTER,GL::NEAREST)
		GL.TexImage2D(
			GL::TEXTURE_2D, 0, 4, @surface.w, @surface.h, 
			0, GL::RGBA, GL::UNSIGNED_BYTE, @surface.pixels
		)
	end
	def bind
		GL.Enable(GL::TEXTURE_2D)
		GL.BindTexture(GL::TEXTURE_2D,@id)
		GL.Enable(GL::POINT_SPRITE)
		GL.TexEnvi(GL::POINT_SPRITE,GL::COORD_REPLACE,GL::TRUE)
	end
	def unbind
		GL.Disable(GL::POINT_SPRITE)
		GL.Disable(GL::TEXTURE_2D)
	end
end
