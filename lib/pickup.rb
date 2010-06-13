require "vector"
class Pickup < Model
	attr_accessor :gentype, :regentype, :gendelay, :lifespan
	attr_accessor :pos, :group, :pickup, :triggermod, :file, :name
	def serialize
		[gentype, regentype, gendelay, lifespan, pos.x, pos.y, pos.z,
		 group, pickup, triggermod].pack("vvfffffvvv")
	end
end
