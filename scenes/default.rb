
####################################
# Physics
####################################

$world = Physics::World.new

def sphere_body s
	body = Physics::SphereBody.new(s)
	$world.add body
	body
end


####################################
# Networking
####################################

$last_sent = Time.now
$pps = 1.0/60.0

class Player < Network::Player
        def post_init
                puts "new player joined from #{@ip}:#{@port}"
		@model = Model.new({
			:file => "nbia400.mxa",
			:body => sphere_body({})
		})
		$render.models << @model
        end
        def receive_data data
		@model.body.unserialize! data
		@model.body.orientation.conjugate!
		# TODO - does rotation velocity also need to be conjugated ?
        end
end

if $options[:peer][:address].nil?
	$network = Network::Server.new($options[:port],Player)
else
	$network = Network::Client.new(
		$options[:peer][:address], 
		$options[:peer][:port], 
		$options[:port],
		Player
	)
end

$update_network = Proc.new {
	if (Time.now - $last_sent).to_f >= $pps
		$network.send_data $player.serialize
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
	pos = $player.pos + $player.orientation.vector( Vector.new(0,0,$player.radius*3) )
	vel = $player.orientation.vector( Vector.new(0,0,100) )
	m = Model.new({
		:file => "ball1.mx", 
		:scale => Vector.new(0.5,0.5,0.5),
		:body => sphere_body({
			:pos => pos,
			:velocity => vel,
			:drag => 0,
			:rotation_velocity => Vector.new(10,10,10),
			:rotation_drag => 0
		})
	})
# TODO - attachments are broken
#	m2 = Model.new({ :file => "ball1.mx", :body => sphere_body({ :pos => Vector.new(0,0,10), })})
#	m2.body.pos = Vector.new(0,0,0)
#	m2.body.velocity = Vector.new
#	m.mesh.attach m2.mesh
	$render.models << m
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
	when :forward  then pressed ? $movement.z =  1 : $movement.z = 0 
	when :back     then pressed ? $movement.z = -1 : $movement.z = 0
	else puts "unknown key binding #{k}"
	end
}

def handle_mouse

	# get accumulated mouse movement
	v = Vector.new( $inputs.mouse_get )
	return unless v.length2 > 0

	# apply mouse accelleration
	v += v * $turn_accell

	# apply movement to velocity
	$player.rotation_velocity += v

end

def handle_keyboard

	return unless $movement.length2 > 0

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

$render = Render.new($options)

$player = sphere_body({
	:pos => Vector.new(-550.0,-500.0,-4600.0),
	:drag => $move_drag,
	:rotation_drag => $turn_drag })
$player.rotate 0,180,180

$render.models << Lines.new
$render.models << Model.new({ :file => "ship.mxv" })
$render.models << Model.new({ :file => "nbia400.mxa", 
	:body => sphere_body({ :pos => Vector.new(-400.0,-500.0,5000.0) })})
$render.models << Model.new({ :file => "xcop400.mxa",
	:body => sphere_body({ :pos => Vector.new(-600.0,-500.0,5000.0) })})


####################################
# Main Loop
####################################

loop do
	$inputs.poll
	$world.update
	$update_network.call
	$render.draw( $player.pos, $player.orientation ) do
		next unless $options[:debug]
		$world.grid.draw
		$world.bodies.each{|body| body.render_radius }
	end
	SDL::WM.setCaption "PXR - FPS: #{$render.fps}", 'icon'
end
