class Score
	def initialize s={}
		@height = s[:height]
		@color = s[:color] || Color::GREEN
		@font = s[:font] || Font.new
		@players = {}
		@widest_name = 0
	end
	def add name
		@players[name] += 1
	end
	def set name, score
		@widest_name = name.length if name.length > @widest_name 
		@players[name] = score
	end
	def get name
		@player[name]
	end
	def draw mode
		x, y = 5, @height - @font.size
		@players.sort.each do |name,score|
			name = sprintf "%-#{@widest_name}s", name
			@font.render "#{name} #{score}", x, y, @color
			y -= @font.size
		end
	end
end
