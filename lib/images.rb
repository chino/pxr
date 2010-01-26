class Images
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
end
