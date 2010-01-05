class FPS
class << self
	@@last_time = 0
	@@frames = 0
	@@fps = 0
	def calc
		@@frames += 1
		t = Time.now
		seconds = (t - @@last_time).to_i
		return @@fps unless seconds >= 1
		@@last_time = t
		@@fps = @@frames / seconds
		@@frames = 0
		@@fps
	end
end
end
