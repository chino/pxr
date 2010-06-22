require 'font'
class Console
	class Line
		attr_accessor :size
		def initialize text, color, font
			@text, @color, @font, @size = 
				text, color, font, font.size
		end
		def draw x, y
			@font.render @text, x, y, @color
		end
	end
	def initialize name, x, y, width, height
		@lines, @name, @x, @y, @width, @height = 
			[], name, x, y, width, height
		@prompt = ""
		@prompt_pos = 0
	end
	def parse_command text
		text.slice! 0
		parts = text.split
		cmd = parts.shift
		case cmd
		when "help"
			add_line "# Usage: /<cmd> [args]...", Color::CYAN
		end
	end
	def key_press c
		case c
		when 275 # right arrow
			@prompt_pos += 1 if @prompt_pos < @prompt.length
		when 276 # left arrow
			@prompt_pos -= 1 if @prompt_pos > 0
		when 13 # enter
			add_line "#{@name}: #{@prompt}", Color::RED
			parse_command @prompt.dup if @prompt[0] =~ /\//
			@prompt = ""
			@prompt_pos = 0
		when 8  # backspace
			return if @prompt_pos < 1
			@prompt_pos -= 1
			@prompt.slice!(@prompt_pos)
		else
			return if c < 32 or c > 126 # ascii char range
			@prompt.insert( @prompt_pos, c.chr )
			@prompt_pos += 1
		end
	end
	def add_line line, color=Color::WHITE, font=Font.new
		@lines.unshift Line.new(line,color,font)
	end
	def pos x, y
		@x, @y = x, y
	end
	def draw mode
		clip_console
		GL.RasterPos @x, @y
		x, y = @x, @y
		font = Font.new
		font.render "> #{@prompt}", x, y, Color::RED
		y += font.size
		@lines.dup.each do |line|
			#break if y > @height # if we support scrolling
			@lines.delete line if y > @height
			line.draw x, y
			y += line.size
		end
		unclip_console
	end
	def clip_console
		GL.Enable GL::CLIP_PLANE0
		GL.Enable GL::CLIP_PLANE1
		GL.ClipPlane(GL::CLIP_PLANE0,[0,1,0,@height])
		GL.ClipPlane(GL::CLIP_PLANE1,[1,0,0,@width])
	end
	def unclip_console
		GL.Disable GL::CLIP_PLANE0
		GL.Disable GL::CLIP_PLANE1
	end
end
