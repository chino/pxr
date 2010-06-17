
####################################
# Physics
####################################

$world = Physics::World.new

def sphere_body s={}
	body = Physics::SphereBody.new(s)
	$world.bodies << body
	body
end


####################################
# Networking
####################################

class Player < Network::Player
	UPDATE = 0
	BULLET = 1
        def post_init
                puts "new player joined from #{@ip}:#{@port}"
		@model = Model.new({
			:file => "nbia400.mxa",
			:body => sphere_body({})
		})
		$render.models << @model
        end
        def receive_data data
		type = data.slice!(0..0).unpack('c')[0]
		case type
		when UPDATE
			@model.body.unserialize! data
		when BULLET
			pos_s, orientation_s = data.unpack("a12a8")
			pos = Vector.new
			pos.unserialize! pos_s, :full
			orientation = Quat.new
			orientation.unserialize! orientation_s, :short
			new_bullet( pos, orientation )
		else
			debug "unknown packet from player #{@id}"
		end
        end
end

if $options[:peer][:address].nil?
	$hosting = true
	$network = Network::Server.new($options[:port],Player)
else
	$hosting = false
	$network = Network::Client.new(
		$options[:peer][:address], 
		$options[:peer][:port], 
		$options[:port],
		Player
	)
end

$last_sent = Time.now
$pps = 1.0/30.0

$update_network = Proc.new {
	if (Time.now - $last_sent).to_f >= $pps
		$network.send_data(
			[Player::UPDATE].pack('c') + 
			$player.serialize
		)
		$last_sent = Time.now
	end
	$network.pump
}


####################################
# Inputs
####################################

$inputs = Input.new($options)

$inputs.mouse_button = Proc.new{|button,pressed|
	next unless pressed
	pos = $player.pos + $player.orientation.vector( Vector.new(0,0,-$player.radius*3) )
	new_bullet( pos, $player.orientation )
	send_bullet( pos, $player.orientation )
}

$movement = Vector.new 0,0,0

$inputs.keyboard = Proc.new{|key,pressed|
	begin
		k = key.chr.downcase.to_sym
	rescue
		next
	end
	b = $bindings[k]
	if b.nil?
		puts "Unknown key binding #{k}"
		next
	end
	#puts "key #{k} #{pressed ? 'pressed':'released'}, binded to #{b}"
	case b
	when :right    then pressed ? $movement.x =  1 : $movement.x = 0 
	when :left     then pressed ? $movement.x = -1 : $movement.x = 0 
	when :up       then pressed ? $movement.y =  1 : $movement.y = 0 
	when :down     then pressed ? $movement.y = -1 : $movement.y = 0 
	when :forward  then pressed ? $movement.z = -1 : $movement.z = 0 
	when :back     then pressed ? $movement.z =  1 : $movement.z = 0
	else puts "unknown key binding #{k}"
	end
}

def handle_mouse

	# get accumulated mouse movement
	v = Vector.new( $inputs.mouse_get )
	return unless v.has_velocity?

	# apply mouse accelleration
	v += v * $turn_accell

	# apply movement to velocity
	$player.rotation_velocity -= v

end

def handle_keyboard

	return unless $movement.has_velocity?

	# convert movement into world coordinates
	movement = $player.orientation.vector($movement)

	# apply movement accelleration
	movement += movement * $move_accell

	# apply movement to velocity
	$player.velocity += movement

end

$inputs.on_poll Proc.new{
	handle_mouse
	handle_keyboard
}


####################################
# Scene
####################################

PLAYER = 2
BULLET = 4
PICKUP = 6

def new_bullet pos, orientation
	vel = orientation.vector( Vector.new(0,0,-100) )
	m = Model.new({
		:file => "ball1.mx", 
		:scale => Vector.new(0.5,0.5,0.5),
		:body => sphere_body({
			:pos => pos,
			:velocity => vel,
			:drag => 0,
			:rotation_velocity => Vector.new(10,10,10),
			:rotation_drag => 0,
			:type => BULLET,
			:mask => [PLAYER]
		})
	})
	$render.models << m
	m
end

def send_bullet pos, orientation
	$network.send_data(
		[Player::BULLET].pack('c') +
		pos.serialize(:full) + 
		orientation.serialize(:short)
	)
end

$render = Render.new($options)

$player = sphere_body({
	:pos => Vector.new(-550.0,-500.0,4600.0),
	:drag => $move_drag,
	:rotation_drag => $turn_drag,
	:type => PLAYER,
	:mask => [BULLET,PLAYER,PICKUP]
})
$player.rotate 180,0,0

$cross_hair = Line.new({
	:pos   => Vector.new($render.width/2,$render.height/2,0),
	:scale => 10,
	:lines => [ [[-1,0],[1,0]], [[0,-1],[0,1]], ]
})
$render.ortho_models << $cross_hair

$render.models << Model.new({
	:file => "nbia400.mxa", 
	:body => sphere_body({
		:pos => Vector.new(-400.0,-500.0,5000.0), 
		:type => PLAYER,
		:mask => [BULLET,PLAYER,PICKUP]
	})
})

$render.models << Model.new({
	:file => "xcop400.mxa",
	:body => sphere_body({
		:pos => Vector.new(-600.0,-500.0,5000.0),
		:type => PLAYER,
		:mask => [BULLET,PLAYER,PICKUP]
	})
})

if $options[:debug]

def collide_body_with_plane body, normal
	m = normal.dot( body.velocity ) # ammount of movement towards plane
	vtp = normal * m                # ammount of velocity towards plane
	vtp += vtp * body.bounce        # multiply velocity by bounce
	body.velocity -= vtp            # apply force to the velocity
end

$level_bsp = FsknBsp.new("data/models/ship.bsp")
rv,node,$in_group = $level_bsp.point_inside_groups?($player.pos, $player.radius)
$level_bsp_update = Proc.new{
	# my position after movement
	stop = $player.pos + $player.velocity
	# I'm outside the level
	if $in_group == -1
		# does my movement put me inside the level ?
		rv,node,$in_group = $level_bsp.point_inside_groups?( stop, $player.radius )
		if $in_group != -1
			puts "hit wall at group #{$in_group} node #{node} from outside"
			# need to walk tree backwards to find proper collision plane
			#collide_body_with_plane $player, node.normal*-1
			$render.models << $level_bsp.render_node(node) if $options[:debug]
		end
	# I'm inside the level
	else
		# does my movement put in outside my last group ?
		rv,node1 = $level_bsp.point_inside_group?( stop, $in_group, $player.radius )
		unless rv # left group
			# am I in a new group or outside level ?
			old_group = $in_group
			rv,node2,$in_group = $level_bsp.point_inside_groups?($player.pos, $player.radius)
			if $in_group != -1
				puts "moved to new level group #{$in_group}"
			else
				$in_group = old_group
				$render.models << $level_bsp.render_node(node1) if $options[:debug]
				pos = $player.pos.dup
				pos.x *= -1
				$render.models << Line.new({:lines => [[
					pos.to_a,
					(pos + (node1.normal * 100)).to_a
				]]}) if $options[:debug]
x=0
while true
				puts "hit wall at group #{$in_group} node #{node1} from inside, count=#{x+=1}"
				collide_body_with_plane $player, node1.normal
	break unless node1.front
	stop = $player.pos + $player.velocity
	rv, node1 = $level_bsp.point_inside_tree?(stop,node1.front,$player.radius)
	break unless rv
end

			end
		end
	end
}

$world.callback = Proc.new{
	$level_bsp_update.call
}

end

$level = Model.new({ :file => "ship.mxv" })
$render.models << $level

if $options[:debug]
	$render.models << Lines.new({:scale => Vector.new(100000,100000,100000)})
	$render.models << $level.mesh.normal_rendering
end

pickups = FsknPic.new("data/models/ship.pic").pickups
pickups.each do |pickup|
	pickup.body.type = PICKUP
	pickup.body.mask = [PLAYER]
end

$picmgr = PickupManager.new({
	:world => $world,
	:render => $render,
	:pickups => pickups,
	:regen_time => 10, # seconds
	:on_pickup => Proc.new{|pickup,player|
		puts "player picked up pickup"
		true # allow to pickup
	}
})

####################################
# Main Loop
####################################

loop do
	$inputs.poll
	$world.update
	$update_network.call
	$picmgr.pump
	$render.draw( $player.pos, $player.orientation ) do
		if $options[:debug]
			$world.bodies.each{|body| body.render_radius }
		end
	end
	SDL::WM.setCaption "PXR - FPS: #{$render.fps}", 'icon'
end
