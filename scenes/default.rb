
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
$camera.drag   = 0.1 # 10% drag
$camera.radius = 20

$step = 10
$bounce = 3.0 # 300%
$accell = 0.5 # 50% of movement
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

$world = [$lines,$ship,$ship2,$ball,$ball2,$sun,$quad]

$movement_physics = Proc.new {

# at what point is movement capped ?

	# apply movement to velocity
	$camera.velocity += ($movement * $accell) if $movement.length > 0

	# apply drag
	$camera.velocity -= $camera.velocity * $camera.drag

	# is there movement to apply ?
	next unless $camera.velocity.length > 0

	# position after movement
	ep  = $camera.dup.move( $camera.velocity )
	epw = ep.dup; epw.z = -epw.z # flipped z

	# detect if movement would cause collision with other objects
	$world.each do |o|
		# point -> plane
		if o.respond_to? :side

			#### local vars

				sep   = ep.dup          # sphere end point
				ssp   = $camera.pos.dup # sphere start point

			#### calc vars

				mv = sep - ssp

			#### collision points on sphere

				# add radius to direction of plane normal to get tip of sphere for contact point
				r = o.normal + $camera.radius
				ssp += r
				sep += r

			#### detect if movement places us on other side of plane

				unless o.side(ssp) != o.side(sep)
					#puts "#{Time.now} No collision"
					next
				end

			#### calc vars

				na = o.normal.dot mv

			#### find collision point on movement vector

				if na == 0.0
					puts "We are moving perpendicular to the plane"
					# we can't continue cause t=(blah/na) would devide by 0
					# collision response should stop us from ever being on the plane anyway
					next
				#elsif na > 0
				#	puts "We are moving with the normal"
				#elsif na < 0
				#	puts "We are moving away from the normal"
				end

				t = -((o.normal.dot(ssp) + o.d) / na)
				cp = ssp + (mv*t)

			#### check if point is within polygon

				unless o.within? cp
					puts "on plane but not not within polygon"
					next
				end

				puts "#{Time.now} polygon collision!"

			#### collision response

=begin
# i need a way to convert the normal from global cords to player cords
# velocity is converted into global space before modifing the global position of the camera
# in View.move you will find  pos += orientation.vector(velocity)
# where orientation.vector is
#   global_vector = quat.normalize * local_vector * quat.conjugate
# thus I need a way to reverse this operation
# perhaps
#	  local_vector  = global_vector / quat.conjugate / quat.normalize
# but then you also need a valid definition of quaternion devision

				# convert normal into the velocity space 
				q  = $camera.orientation.normalize
				qn = o.normal.quat / q.conjugate / q

				# quat needs convert to vec -- w should be 0 now
				n  = Vector.new( qn.x, qn.y, qn.z )
				
				# restore movement in direction of normal
				n *= na
	
				# increase strength by bounciness
				#n *= $bounce

# hmmm converting into local cords will also need -z flip !

				# remove from velocity
				$camera.velocity -= n
=end

# for now since the above doesn't really work i can simply modify the camera pos which
# is already in global cords just like the normal is and then simply let the movement apply
# if you ask me i still think this approach works better.... 
# it's simple and gives a good enough effect

# with this trick it's basically the same affect slightly hackish but no information is lost
# one case I can think that show's how it's better
# this is of course with regards to how movement is currently done based on key press/release

#   the players original direction is lost after modifing the velocity
#   once the player slides off of the polygon he will continue to move along it's plane
#   unless he lets go of the buttons and presses them again
#   they should of proceeded in the original direction before modifying the velocity

				# movement in direction of normal with bounciness
				$camera.pos -= o.normal * na * $bounce

		# sphere -> sphere
		else
			cd = o.radius + $camera.radius # collision distance
			cv = (o.pos - epw) # collision vector
			d = cv.length # distance
			if d < cd
				puts "#{Time.now} collision!"
				cvn = cv.normalize
				# move back on collision vector by collision distance
				# allow movement to happen anyway to give a simple bounce effect
				$camera.pos -= cvn * cd * $bounce
			end
		end
	end

	# apply movement
	$camera.move $camera.velocity
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
