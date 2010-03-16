$game  = Game.new("Model Viewer", $options[:width], $options[:height], $options[:fullscreen])

$quad = Quad.new

# location of the center
$x = $y = Math.sqrt($quad.verts.length/4)/2

# settings
$speed = 10
$height = 4

def normalize x,y
	dot = x*x + y*y
	length = Math.sqrt dot
	[x/length, y/length]
end

# alter verts
$wave = Proc.new{
	t = Time.now.to_f * $speed
	$quad.verts.each do |vert|
		x,y = vert[:vector]

		# vector from current point (x,y) to center ($x,$y)
		x1,y1 = (x-$x),(y-$y)

		# dot product of vector with it self is same as length of vector
		distance = Math.sqrt(x1*x1+y1*y1).abs
	
		# normalized vector from center to point
		x1,y1 = normalize x1, y1 unless x1==0 and y1==0

		# refrence point to determine angle
		x2,y2 = normalize 1, 1

		# angle between two points
		angle = Math.acos( x1*x2 + y1*y2 ) * $height

		#
		vert[:vector][2] = Math.cos(angle-t) * $height
	end
}

$objects = [$quad,Lines.new]

$camera     = View.new
$camera.pos = Vector.new 927.193559446316,922.95736324225,-1640.84719642008
$camera.orientation = Quat.new 0.0185038595272231,0.0268171902854991,0.176251223933536,0.983805850536435

$step = 5
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

GL.Disable(GL::CULL_FACE)
GL.PolygonMode(GL::FRONT, GL::LINE)
GL.PolygonMode(GL::BACK, GL::LINE)


$game.display = Proc.new{

#puts $camera.pos.to_s
#puts $camera.orientation.to_s

	# read mouse for rotation
	x,y = $game.mouse_get

	# apply rotation
	$camera.rotate x, y

	# apply movement
	$camera.move $movement

	# modify coordinate system based on camera position
	$camera.place_camera

	# draw at their locations
	$objects.each do |o|
		GL.PushMatrix
		o.load_matrix
		o.draw
		GL.PopMatrix
	end

	# move back to the camera
	GL.LoadIdentity

	#
	$wave.call
}

$game.run
