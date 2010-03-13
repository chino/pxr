$window  = Window.new("Model Viewer", $options[:width], $options[:height], $options[:fullscreen])

GL.Disable(GL::CULL_FACE)

$network = Network.new( $options[:peer][:address], $options[:peer][:port], $options[:port] ) if $options[:peer][:address]

$ship2       = Model.new("nbia400.mxa")
$lines       = Lines.new
$level       = Model.new("ship.mxv")
$fusionfarm  = Model.new("fusnfarm.rdl")
$ball        = Model.new
$ball2        = Model.new
$suss					= Model.new "ssus.mx"
#$suss					= Model.new "pulsegun.mx"

$ball.pos       = Vector.new 3000,3000,3000
$ball2.pos       = Vector.new -3000,-3000,-3000
$ship2.pos      = Vector.new 550,-500,-5000
$fusionfarm.pos = Vector.new 1000,-5000,4000

$fusionfarm.scale = Vector.new 20,20,20
$ball.scale = Vector.new 0.5,0.5,0.5

$ship      = Model.new("sxcop400.mxa")
$ship.pos  = Vector.new -100,100,100
$ship.attach $lines

$suss2	   = Model.new "ssus.mx"
$suss2.scale = Vector.new 0.5,0.5,0.5
$suss2.pos = Vector.new 20,-25,-40
$suss2.rotate 0,0,180
$ship.attach $suss2

$sun = Model.new
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

$objects = [$level,$fusionfarm,$lines,$ship,$ship2,$ball,$ball2,$sun]
$world = [$lines,$ship,$ship2,$ball,$ball2,$sun]

$camera     = View.new
$camera.pos = Vector.new -100,-50,-500

$step = 30
$movement = Vector.new 0,0,0
$radius = 10
$bindings = {
	:w => :forward,
	:s => :back,
	:e => :up,
	:d => :down,
	:f => :left,
	:g => :right
}
$window.keyboard = Proc.new{|key,x,y,pressed|
	k = key.chr.downcase.to_sym
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
$players = {}
$last_send = Time.now
$window.display = Proc.new{

	# detect collisions with local player
	$world.each do |o|
		distance = (o.pos - $camera.pos).length
		collision_distance = ($radius + $radius) # o.radius + $camera.radius
		if distance < collision_distance
			puts "#{Time.now} Collision!!!! distance=#{distance} threshold=#{collision_distance}"
		else
if o == $ship
	puts "#{Time.now} here distance=#{distance}"
end
		end
	end

	# get network updates
	unless $network.nil?
		# read data from player
		data,info = $network.pump 
		something,port,name,ip = info
		player = $players[ip]
		if player.nil?
			player = $players[ip] = Model.new("nbia400.mxa")
			$objects << player
		end
		if data
			player.unserialize! data
		end
		# send current update
		#if (Time.now - $last_send).to_i > (60/10)
			$network.send $camera.serialize
			$last_send = Time.now
		#end
	end

	# rotate ball
	$ball.rotate 5,5,5
	$ball2.rotate -5,-5,-5
	
	# read mouse for rotation
	x,y = Mouse.get

	# apply rotation
	$camera.rotate x, y

	# apply movement
	$camera.move $movement

	# modify coordinate system based on camera position
	$camera.place_camera

	# plantary orbits
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

	# draw at their locations
	$objects.each do |o|
		GL.PushMatrix
		o.load_matrix
		o.draw
		GL.PopMatrix
	end

	# move back to the camera
	GL.LoadIdentity

	# draw attached gun
	$suss.load_matrix
	$suss.draw

}
$suss.pos = Vector.new 90,-40,130
$suss.rotate 180,-10,220

$window.run
