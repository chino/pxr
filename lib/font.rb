require "ftgl"
class Font
	@@font = {}
	attr_accessor :size
	def initialize file="data/fonts/FreeMono.ttf", size=24
		@file, @size = file, size
		@@font[@file] ||= FTGL::PixmapFont.new(@file)
		@font = @@font[@file]
		set_size @size
	end
	def set_size size
		@font.SetFaceSize(24)
		@size = size
	rescue
		$stderr.puts "SetFaceSize(#{size}) failed for #{@font}"
	end
	def render text, x=0, y=0, color
		GL.Color4ubv color
		GL.RasterPos x, y
		set_size @size
		@font.Render text
	end
end
