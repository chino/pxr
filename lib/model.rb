class Model < View
	@@dir = "data/models"
	@@loaders = {
		"mxa" => FsknMx,
		"mxv" => FsknMx,
		"rdl" => D1rdl
	}
	@@models = {}
	def initialize file="ball1.mx"
		super
		@path = "#{@@dir}/#{file}"
		ext = @path.split('.').last.downcase
		@model ||= @@models[@path]
		return unless @model.nil?
		loader = @@loaders[ext]
		throw "cannot determine model loader" if loader.nil?
		@model = loader.new @path
	end
	def draw
		@model.draw
	end
end
