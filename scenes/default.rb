
# create game 


$game = Game.new("Model Viewer", $options[:width], $options[:height], $options[:fullscreen])
$game.wireframe

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
$level.collision = :mesh

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
$accell = 10.0
$bounce = 0.5

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

$world = [$ship,$ship2,$ball,$ball2,$sun,$level]
$pi2 = sprintf('%.14f',Math::PI * 2).to_f

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
		if o.respond_to? :collision and o.collision == :mesh

				va = o.model.verts # vertex array

o.model.primitives.each do |p|

				normal = Vector.new p[:normal]

			#### local vars

				sep   = ep.dup          # end point
				ssp   = $camera.pos.dup # start point

			#### amount in direction of normal	

				na = normal.dot $camera.velocity

			#### are we perpendicular to the plane ?

				# we can't continue cause t=(blah/na) would devide by 0
				# collision response would have pushed us away from plane by now anyway
				# so we don't really need to worry about doing anything here
				if na == 0.0
					debug "We are moving perpendicular to the plane"
					next
				end

			#### collision points on sphere

				# vector the length of radius in direction of normal 
				r = normal + $camera.radius

				# flip the direction to point towards the plane
				r *= -1 if na < 0

				# add radius to the center to get tip of sphere for contact point
				#ssp += r
				#sep += r

			#### calculate the plane formula

				d = (-normal.x*p[:pos][0]) - (normal.y*p[:pos][1]) - (normal.z*p[:pos][2])

			#### detect if movement places us on other side of plane

				start_distance = normal.dot(ssp) + d
				start_side = (start_distance > 0.0) ? :front : 
											(start_distance < 0.0) ? :back :
											:coincide

				end_distance = normal.dot(sep) + d
				end_side = (end_distance > 0.0) ? :front : 
											(end_distance < 0.0) ? :back :
											:coincide

				if start_side == end_side
					#debug "#{Time.now} No collision"
					next
				end

			#### find collision point on movement vector
#
# apparently I'm able to get right through the middle of two triangle
# by hitting the crack between them
# 
# what I probably need is ability to detect if the entire width of my object moving
# causes a collision... 
#
# not just the exact point of my center position crossing the plane
#

				t = -((normal.dot(ssp) + d) / na)
				cp = ssp + ($camera.velocity*t)

			#### check if point is within polygon

				# add angle between consequtive verts and cp
				radians = 0
				p[:verts].length.times do |i|
					i2 = p[:verts][i+1].nil? ? 0 : i+1 # [i+1] or [0]
					v1 = (Vector.new( va[p[:verts][i ]][:vector] ) - cp ).normalize
					v2 = (Vector.new( va[p[:verts][i2]][:vector] ) - cp ).normalize
begin
					radians += Math.acos(v1.dot(v2))
rescue
	puts "acos arg out of range need to figure out what's wrong here"
	puts p[:verts]
	next
end
				end
				radians = sprintf('%.14f',radians).to_f

				# if add up to 360 degrees then point is within poly
				unless radians == $pi2
					debug "#{Time.now} not within polygon - #{radians} != #{$pi2}" if radians > 4
					next
				end

				#debug "#{Time.now} polygon collision!"

			#### collision response

				# ammount of movement in direction of normal
				m = normal * na

				# increase by bounce factor
				m += m * $bounce

				# apply to velocity
				$camera.velocity -= m

end # primitives.each

		# sphere -> sphere
		else

			#### detect collision

				# width of both objects combined
				cd = o.radius + $camera.radius

				# collision vector
				cv = (o.pos - epw)

				# distance along vector
				d = cv.length

				# are we close enough to collide?
				next unless d < cd
				#debug "#{Time.now} collision!"

			#### collision response

				cvn = cv.normalize
	
				# remove all movement in direction of collision
				m = cvn * cvn.dot( $camera.velocity )
	
				# add bounce based on amount of collision
				m += m * $bounce

				# apply to velocity
				$camera.velocity -= m

		end
	end

	# apply movement
	$camera.pos += $camera.velocity
}

$turn = Vector.new
$turn_accell = 1.0
$turn_drag = 0.5

$turn_physics = Proc.new{

	x,y = $game.mouse_get

=begin
	# need to convert to -1->1 based on mouse sensitivity

	# smooth scrolling ?
	x *= x.abs
	y *= y.abs
=end

	inputs = Vector.new x,y

	# apply accelleration
	inputs += inputs * $turn_accell

	# add current movement to existing turn velocity
	$turn += inputs

	#
	next unless $turn.length > 0

	# apply drag
	$turn -= $turn * $turn_drag

	# apply current rotation
	$camera.rotate $turn

}

$updates.unshift Proc.new{
	$turn_physics.call
	$movement_physics.call
	$camera.place_camera
}



# run the game

$game.run
