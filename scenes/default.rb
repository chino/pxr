
# create game 


$game = Game.new("Model Viewer", $options[:width], $options[:height], $options[:fullscreen])

$updates = []

$game.display = Proc.new{
	$updates.each{|update| update.call }
}



# network interface


$network = Network.new( 
	$options[:peer][:address], $options[:peer][:port], $options[:port] 
) if $options[:peer][:address]

$players = {}
$last_send = Time.now

if $network
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



# setup scene objects


$lines     = Lines.new

$ship2       = Model.new("nbia400.mxa")
$ship2.pos   = Vector.new 550,-500,-5000

$ship      = Model.new("sxcop400.mxa")
$ship.pos  = Vector.new -100,100,100
$suss2	     = Model.new "ssus.mx"
$suss2.scale = Vector.new 0.5,0.5,0.5
$suss2.pos   = Vector.new 20,-25,-40
$suss2.rotate 0,0,180
$ship.attach $suss2

$level       = Model.new("ship.mxv")

$fusionfarm  = Model.new("fusnfarm.rdl")
$fusionfarm.pos = Vector.new 1000,-5000,4000
$fusionfarm.scale = Vector.new 20,20,20

$ball        = Model.new
$ball.pos    = Vector.new 3000,3000,3000
$ball.scale = Vector.new 0.5,0.5,0.5

$ball2       = Model.new
$ball2.pos   = Vector.new -3000,-3000,-3000

$updates << Proc.new{
	$ball.rotate 5,5,5
	$ball2.rotate -5,-5,-5
}
	
$sun     = Model.new
$sun.pos = Vector.new 500,500,-1000

$earth = Model.new
$earth.scale = Vector.new 0.5,0.5,0.5
$sun.attach $earth

$moon = Model.new
$moon.scale = Vector.new 0.2,0.2,0.2
$earth.attach $moon

$mars = Model.new
$mars.scale = Vector.new 0.3,0.3,0.3
$sun.attach $mars

$updates << Proc.new{
	$earth.orbit(
		Vector.new(0,0,0),
		200,0,0, # radius / distance / direction - from position
		5,0,0 # rotate speed 
	)
	$moon.orbit(
		Vector.new(0,0,0),
		100,0,0, # radius / distance / direction - from position
		20,0,0 # rotate speed 
	)
	$mars.orbit(
		Vector.new(0,0,0),
		500,0,0, # radius / distance / direction - from position
		3,0,0 # rotate speed 
	)
}

# object to draw

$objects = [$level,$fusionfarm,$lines,$ship,$ship2,$ball,$ball2,$sun]

$updates << Proc.new{
	$objects.each do |o|
		GL.PushMatrix
		o.load_matrix
		o.draw :opaque
		GL.PopMatrix
	end
	Mesh.set_trans
	$objects.each do |o|
		GL.PushMatrix
		o.load_matrix
		o.draw :trans
		GL.PopMatrix
	end
	Mesh.unset_trans
}


# local player 


$camera     = View.new
$camera.pos = Vector.new -100,-50,-500

$step = 10
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
	when :right then pressed ? $movement.x += $step : $movement.x = 0 
	when :left then pressed ? $movement.x -= $step : $movement.x = 0 
	when :up then pressed ? $movement.y += $step : $movement.y = 0 
	when :down then pressed ? $movement.y -= $step : $movement.y = 0 
	when :forward then pressed ? $movement.z += $step : $movement.z = 0 
	when :back then pressed ? $movement.z -= $step : $movement.z = 0
	else puts "unknown key binding #{k}"
	end
}


# camera/collision physics

$world = [$lines,$ship,$ship2,$ball,$ball2,$sun]

$updates.unshift Proc.new{

	x,y = $game.mouse_get

	$camera.rotate x, y

	# apply movement
	radius = 20 # radius of object collision
	collision_distance = (radius + radius) # o.radius + $camera.radius
	camera = $camera.dup
	camera.move $movement
	camera.pos.z *= -1

	# detect collisions with local player if we allow movement
	$world.each do |o|
		collision_vec = (o.pos - camera.pos)
		distance = collision_vec.length
		if distance < collision_distance
			puts "#{Time.now} Collision!!!!"
			c = collision_vec.normalize
			$movement -= c * $movement.dot(c)
		end
	end

	# apply movement if no collision would result
	$camera.move $movement

	# modify coordinate system based on camera position
	$camera.place_camera

}



# run the game

$game.run
