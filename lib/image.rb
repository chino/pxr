require 'RMagick'
class Image
	include Magick
	attr_accessor :image
	def initialize path
		@image = ImageList.new(path)[0]
		@data = @image.export_pixels_to_str(
			0,0,@image.columns,@image.rows,"RGBA",CharPixel
		)
		@id = GL.GenTextures(1)[0]
		#puts "generated texture #{@id}"
		bind
		GLU.Build2DMipmaps(
			GL::TEXTURE_2D, 
			GL::RGBA, 
			@image.columns,
			@image.rows,
			GL::RGBA, 
			GL::UNSIGNED_BYTE,
			@data
		)
		unbind
	end
	def bind
		GL.Enable(GL::TEXTURE_2D)
		GL.BindTexture(GL::TEXTURE_2D, @id)
	end
	def unbind
		GL.Disable(GL::TEXTURE_2D)
	end
end
