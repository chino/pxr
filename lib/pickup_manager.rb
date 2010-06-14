require 'pickup'
class PickupManager
	def initialize s={}
		@on_pickup = s[:on_pickup]
		@world = s[:world]
		@render = s[:render]
		s[:pickups].each do |pickup|
			add pickup
		end
	end
	def add pickup
		@world.add pickup.body
		@render.models << pickup
		pickup.body.on_collision = Proc.new{|pickup,player|
			@on_pickup.call pickup, player
		}
	end
end
