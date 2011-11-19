require 'pickup'
class PickupManager
	def initialize s={}
		@regen = []
		@regen_time = s[:regen_time]
		@on_pickup = s[:on_pickup]
		@world = s[:world]
		@render = s[:render]
		@pickups = []
		s[:pickups].each do |pickup|
			add pickup
		end
	end
	def add pickup
		@world.add pickup.body
		@render.models << pickup
		pickup.body.on_collision = Proc.new{|pickup,player|
			pickup = find_pickup_by_body( pickup )
			if @on_pickup.call( pickup, player )
				@world.remove pickup.body
				@render.models.delete pickup
				@regen << {
					:pickup => pickup,
					:time => Time.now
				}
			end
			false # do not allow collision response
		}
		@pickups << pickup
	end
	def find_pickup_by_body body
		@pickups.each do |pickup|
			return pickup if pickup.body == body
		end
	end
	def pump
		@regen.dup.each do |regen|
			if Time.now - regen[:time] > @regen_time
				add regen[:pickup]
				@regen.delete regen
			end
		end
	end
end
