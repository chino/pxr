
####################################
# Game 
####################################

$game = Game.new(
	"Model Viewer", 
	$options[:width], 
	$options[:height], 
	$options[:fullscreen]
)

# add routines to $updates to run each frame
$updates = []
$game.display = Proc.new{ $updates.each{|update| update.call } }


####################################
# Physics
####################################

$world = Physics::World.new

$updates << Proc.new{
	$world.update
}

def sphere_body s
	body = Physics::SphereBody.new(s)
	$world.bodies << body
	body
end


####################################
# network interface
####################################

if $options[:peer][:address]

	$network = Network.new( 
		$options[:peer][:address], 
		$options[:peer][:port], 
		$options[:port] 
	)

	$players = {}
	$last_send = Time.now

	$updates << Proc.new {

		# read data from players
		data,info = $network.pump 
		something,port,name,ip = info
		player = $players[ip]
		if player.nil?
			player = $players[ip] = Model.new("nbia400.mxa")
			$objects << player
		end
		player.unserialize! data if data

		# send current update
		#if (Time.now - $last_send).to_i > (60/10)
			$network.send $camera.serialize
			$last_send = Time.now
		#end

	}
end


####################################
# Camera
####################################

$camera = sphere_body({ :pos => Vector.new(0,0,500) })
$camera.rotate 0,180,180

$updates << Proc.new{
	Camera.place(
		$camera.pos,
		$camera.orientation
	)
}


####################################
# Inputs
####################################

$game.mouse_button = Proc.new{|button,pressed|
	next unless pressed
	pos = $camera.pos + $camera.orientation.vector(
		Vector.new(0,0,$camera.radius*2)
	)
	$objects << Model.new(
		"ball1.mx",
		sphere_body({
			:pos => pos,
			:velocity => Vector.new(0,0,100),
			:drag => 0,
			:rotation_velocity => Vector.new(10,10,10),
			:rotation_drag => 0
		})
	)
}

$updates << Proc.new{

	x,y = $game.mouse_get

	inputs = Vector.new x,y

	# apply mouse accelleration
	inputs += inputs * $turn_accell

	# apply movement to velocity
	$camera.rotation_velocity += inputs

}

$movement = Vector.new 0,0,0

$game.keyboard = Proc.new{|key,pressed|
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

$updates << Proc.new{
	next unless $movement.length > 0

	# convert movement into world coordinates
	movement = $camera.orientation.vector($movement)

	# apply movement accelleration
	movement += movement * $move_accell

	# apply movement to velocity
	$camera.velocity += movement
}

####################################
# Scene
####################################

$lines = Lines.new
$level = Model.new( "ship.mxv" )
$nubia = Model.new( "nbia400.mxa",  sphere_body({ :pos => Vector.new(-550,-500,-5000) }) )
$xcop  = Model.new( "sxcop400.mxa", sphere_body({ :pos => Vector.new(-600,-500,-5000) }) )

# models to draw
$objects = [$level,$lines,$xcop,$nubia]

radius = 50
diameter = radius * 2
100.times do |x|
	o = rand(x) - x/2
	p = o * diameter
	ball = Model.new(
		"ball1.mx",
		sphere_body({
			:pos => Vector.new(p,p,p),
			:velocity => Vector.new(rand(10),rand(10),rand(10)),
			:drag => 0,
			:radius => radius
			
		})
	)
	$objects << ball
end

# draw routine
$updates << Proc.new{
	# draw solid
	$objects.each do |o|
		GL.PushMatrix
		o.load_matrix
		o.draw :opaque
		GL.PopMatrix
	end
	# draw transparent
	Mesh.set_trans
	$objects.each do |o|
		GL.PushMatrix
		o.load_matrix
		o.draw :trans
		GL.PopMatrix
	end
	Mesh.unset_trans
}


####################################
# Main Loop
####################################

$game.run

