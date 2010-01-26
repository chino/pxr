$window  = Window.new("Model Viewer", 640, 480)

# example of ruby-opengl throwing gl errors
#GL.Enable(GL_TRUE) # will raise exception

# glut.init was crashing if i passed in argv[1] ???
$host,$port,$lport = (ARGV[1]||"").split(":")
$port = $port || 2300
$lport = $lport || 2300
$network = Network.new( $host, $port, $lport ) if ARGV.length > 1

$ship        = Model.new("sxcop400.mxa")
$ship2       = Model.new("nbia400.mxa")
$ship3       = Model.new("nbia400.mxa")
$lines       = Lines.new
$level       = Model.new("ship.mxv")
$fusionfarm  = Model.new("fusnfarm.rdl")
$ball        = Model.new

$ball.pos       = Vector.new 100,100,100
$ship.pos       = Vector.new 500,-500,-5000
$ship2.pos      = Vector.new 550,-500,-5000
$fusionfarm.pos = Vector.new 1000,-5000,4000

$fusionfarm.scale = Vector.new 20,20,20

$camera     = View.new
$camera.pos = Vector.new -100,-50,-500

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

$last_send = Time.now
$window.display = Proc.new{

	# get network updates
	unless $network.nil?
		# read data from player
		data = $network.pump 
		if data
			px,py,pz,ox,oy,oz,ow = data.unpack("eeeeeee")
			$ship3.pos = Vector.new px,py,-pz
			$ship3.orientation = Quat.new(ox,oy,oz,ow)
		end
		# send current data
		#if (Time.now - $last_send).to_i > (60/10)
			$network.send [
				$camera.pos.x, 
				$camera.pos.y, 
				$camera.pos.z,
				$camera.orientation.x,
				$camera.orientation.y,
				$camera.orientation.z,
				$camera.orientation.w,
			].pack("eeeeeee")
			$last_send = Time.now
		#end
	end

	# rotate ball
	$ball.rotate 5,5,5
	
	# read mouse for rotation
	x,y = Mouse.get

	# apply rotation
	$camera.rotate x, y

	# apply movement
	$camera.move $movement

	# modify coordinate system based on camera position
	$camera.place_camera

	# draw at their locations
	[$level,$fusionfarm,$lines,$ship,$ship2,$ship3,$ball].each do |o|
		GL.PushMatrix
		o.load_matrix
		o.draw
		GL.PopMatrix
	end
	
}

$window.run
