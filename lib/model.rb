require 'd1rdl'
require 'fsknmx'
class Model < View
	@@dir = "data/models"
	@@loaders = {
		"mx"  => FsknMx,
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
		@attachments = []
	end
	def draw
		@model.draw
		# each transformation starts from the parent objects perspective
		# you can attach models to child objects if you want to chain down
		@attachments.each do |attachment|
			GL.PushMatrix
			attachment.load_matrix
			attachment.draw
			GL.PopMatrix
		end
	end
	def attach model
		@attachments << model
	end
	def detach model
		@attachments.delete model
	end
end
