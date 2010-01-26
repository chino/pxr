require 'RMagick'
class Image
	include Magick
	class << self
		@@images = {}
		def get image
			return nil if image.nil?
			return nil if @@images[image] == false
			return @@images[image] unless @@images[image].nil?
			unless File.exist? image
				@@images[image] = false
				return nil
			end
			@@images[image] = Image.new image
			@@images[image]
		end
		def bind image
			i = get image
			i.bind unless i.nil?
		end
		def unbind image
			i = get image
			i.unbind unless i.nil?
		end
	end
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
