
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
	$world.add body
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

	$updates << Proc.new {

		# send my position
		$network.send $camera.serialize

		# read data from players
		data,info = $network.pump 
		next if data.nil?
		something,port,name,ip = info
		$players[ip] = model( "nbia400.mxa", sphere_body({}) ) if $players[ip].nil?
		$players[ip].body.unserialize! data 

	}

end


####################################
# Camera
####################################

$camera = sphere_body({ 
	:pos => Vector.new(0,0,500),
	:drag => $move_drag
})
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
	pos = $camera.pos + $camera.orientation.vector( Vector.new(0,0,$camera.radius*3) )
	vel = $camera.orientation.vector( Vector.new(0,0,100) )
	$models << Model.new(
		"ball1.mx",
		sphere_body({
			:pos => pos,
			:velocity => vel,
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

$models = [] # objects to draw

def model *args
	model = Model.new( *args )
	$models << model
	model
end

$b = sphere_body({ :pos => Vector.new( 0,0,0 ) })
m = model( "xcop400.mxa", $b )
$b.compute_radius( m.model.verts )
puts "radius = " + $b.radius.to_s

verts = []; m.model.verts.each do |vert|
	vert[:vector][2] = -vert[:vector][2]
	verts << [vert[:vector],nil,nil]
end
verts << [[$b.radius,0],[255,0,0,0]]
verts << [[-$b.radius,0],[255,0,0,0]]
verts << [[0,$b.radius,0],[255,0,0,0]]
verts << [[0,-$b.radius,0],[255,0,0,0]]
verts << [[0,0,$b.radius],[255,0,0,0]]
verts << [[0,0,-$b.radius],[255,0,0,0]]
points = Point.new(verts)
points.make_dl
$models << points
puts "points done"

# draw routine
$updates << Proc.new{
	$models.each do |o|
		GL.PushMatrix
		o.load_matrix
		o.draw :opaque
		GL.PopMatrix
	end
}


####################################
# Main Loop
####################################

$game.run

