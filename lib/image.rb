require 'RMagick'
class Image
	include Magick
	class << self
		@@images = {}
		def get image, *args
			return nil if image.nil?
			return nil if @@images[image] == false
			return @@images[image] unless @@images[image].nil?
			unless File.exist? image
				debug "Image not found: #{image}"
				@@images[image] = false
				return nil
			end
			debug "Image found: #{image}"
			@@images[image] = Image.new image, *args
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
	attr_accessor :image, :colorkey
	def initialize path, colorkey=false
		@image = ImageList.new(path)[0]
		# only forsaken uses the old color key trick
		# fsknmx will pass true for colorkey always as a hint
		# but we only apply it if there is no alpha channel (this is the standard)
		# colorkeying is done by setting alpha channel transparent on black pixels
		# during drawing alpha test completely ignores the pixel during drawing
		@colorkey = colorkey
		@image = @image.transparent "black" if @colorkey and @image.opaque?
		@data = @image.export_pixels_to_str(
			0,0,@image.columns,@image.rows,"RGBA",CharPixel
		)
		@id = GL.GenTextures(1)[0]
		bind
		@anisotropic = 0.0
		if Gl.is_available?("GL_EXT_texture_filter_anisotropic")
			@anisotropic = GL.GetFloatv(GL::MAX_TEXTURE_MAX_ANISOTROPY_EXT)
			GL.TexParameterf(GL::TEXTURE_2D, GL::TEXTURE_MAX_ANISOTROPY_EXT, @anisotropic)
		end
		# when texture area is small, bilinear filter the closest mipmap
		GL.TexParameterf( GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR_MIPMAP_NEAREST )
		# when texture area is large, bilinear filter the original
		GL.TexParameterf( GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR )
		# the texture wraps over at the edges (repeat)
		GL.TexParameterf( GL::TEXTURE_2D, GL::TEXTURE_WRAP_S, GL::REPEAT )
		GL.TexParameterf( GL::TEXTURE_2D, GL::TEXTURE_WRAP_T, GL::REPEAT )
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
