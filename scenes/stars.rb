$window  = Window.new("Model Viewer", $options[:width], $options[:height], $options[:fullscreen])

# camera and movement

$camera = View.new
$camera.pos = Vector.new 500,500,-4000
$step = 100
$movement = Vector.new 0,0,0
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
def handle_inputs
	# read mouse for rotation
	x,y = Mouse.get

	# apply rotation
	$camera.rotate x, y

	# apply movement
	$camera.move $movement

	# modify coordinate system based on camera position
	$camera.place_camera
end

# networking

$network = Network.new( $options[:peer][:address], $options[:peer][:port], $options[:port] ) if $options[:peer][:address]
$players = {}
$last_send = Time.now
def handle_network
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
end

# render objects

$points = Point.new
$points.verts = []
$points.primitives = []
$range = 5000
$half = $range/2
def _rand
	rand($range)-$half
end
5000.times {|i|
	x,y,z = _rand,_rand,_rand
	$points.verts << { :vector => [x,y,z], :rgba => [255,255,255,255] }
	$points.primitives << { :texture => nil, :verts => [i] }
}
$points.make_dl;$points.verts = [];$points.primitives = []
$points2 = $points.dup
$front = $points
$back = $points2
$points_offset = 0
$speed = 100
def update_points
	# swap blocks
	if $points_offset > 500 
		$points_offset = (500-250)
		$front.pos.z = 0
		$back.pos.z = 0
		front = $front
		back = $back
		$front = back
		$back = front
	end
	# follow camera
	$front.pos.x = $camera.pos.x
	$front.pos.y = $camera.pos.y
	$front.pos.z = -$camera.pos.z
	$back.pos.x = $camera.pos.x
	$back.pos.y = $camera.pos.y
	$back.pos.z = -$camera.pos.z
	# move past on z
	$points_offset += $speed
	$front.pos.z += $points_offset
	$back.pos.z += $points_offset
	# draw main stars
	GL.PushMatrix
	$front.load_matrix
	$front.draw
	# draw following stars
	GL.Translate 0,0,$range
	$back.draw
	GL.PopMatrix
end

$lines = Lines.new
$objects = [$lines]
def draw_objects
	$objects.each do |o|
		GL.PushMatrix
		o.load_matrix
		o.draw
		GL.PopMatrix
	end
end

# main display loop

$window.display = Proc.new{
	handle_network
	handle_inputs
	draw_objects
	update_points
}

$window.run
