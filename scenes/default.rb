
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

$quad = Quad.new

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

$objects = [$level,$fusionfarm,$lines,$ship,$ship2,$ball,$ball2,$sun,$quad]

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


$camera        = View.new
$camera.pos    = Vector.new -100,-50,-500

$drag   = 0.1
$accell = 0.5
$bounce = 1.5 # 150 percent

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


# camera/collision physics

$world = [$lines,$ship,$ship2,$ball,$ball2,$sun,$quad]

$movement_physics = Proc.new {

	if $movement.length > 0

		# convert movement into world space
		movement = $camera.orientation.vector($movement)

		# increase movement vector by accelleration
		movement += movement * $accell

		# apply movement to velocity
		$camera.velocity += movement

	end

	# apply drag
	$camera.velocity -= $camera.velocity * $drag

	# is there movement to apply ?
	next unless $camera.velocity.length > 0

	# position after movement
	ep  = $camera.dup.pos += $camera.velocity
	epw = ep.dup; epw.z = -epw.z # flipped z

	# detect if movement would cause collision with other objects
	$world.each do |o|
		# point -> plane
		if o.respond_to? :side

			#### local vars

				sep   = ep.dup          # end point
				ssp   = $camera.pos.dup # start point

			#### amount in direction of normal	

				na = o.normal.dot $camera.velocity

			#### are we perpendicular to the plane ?

				# we can't continue cause t=(blah/na) would devide by 0
				# collision response would have pushed us away from plane by now anyway
				# so we don't really need to worry about doing anything here
				if na == 0.0
					puts "We are moving perpendicular to the plane"
					next
				end

			#### collision points on sphere

				# vector the length of radius in direction of normal 
				r = o.normal + $camera.radius

				# flip the direction to point towards the plane
				r *= -1 if na < 0

				# add radius to the center to get tip of sphere for contact point
				ssp += r
				sep += r

			#### detect if movement places us on other side of plane

				unless o.side(ssp) != o.side(sep)
					#puts "#{Time.now} No collision"
					next
				end

			#### find collision point on movement vector

				t = -((o.normal.dot(ssp) + o.d) / na)
				cp = ssp + ($camera.velocity*t)

			#### check if point is within polygon

				unless o.within? cp
					puts "on plane but not not within polygon"
					next
				end

				puts "#{Time.now} polygon collision!"

			#### collision response

				# remove movement in direction of normal * bounce factor
				$camera.velocity -= o.normal * na * $bounce

		# sphere -> sphere
		else
			cd = o.radius + $camera.radius # collision distance
			cv = (o.pos - epw) # collision vector
			d = cv.length # distance
			if d < cd
				puts "#{Time.now} collision!"
				# remove movement in direction of collision * bounce factor
				cvn = cv.normalize
				ca = cvn.dot $camera.velocity
				$camera.velocity -= cvn * ca * $bounce
			end
		end
	end

	# apply movement
	$camera.pos += $camera.velocity
}

$updates.unshift Proc.new{

# still need some rotation velocity here

	x,y = $game.mouse_get
	$camera.rotate x, y

	$movement_physics.call

	$camera.place_camera

}



# run the game

$game.run
