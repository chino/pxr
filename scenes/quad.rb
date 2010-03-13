$window  = Window.new("Model Viewer", $options[:width], $options[:height], $options[:fullscreen])

$quad = Quad.new

$wave = Proc.new{
	$quad.verts.each do |vert|
		case vert[:vector][2]
		when 0 then vert[:vector][2] = 1000
		when 1000 then vert[:vector][2] = -1
		when -1 then vert[:vector][2] = -1000
		when -1000 then vert[:vector][2] = 0
		end
	end
}

$objects = [$quad]

$camera     = View.new
$camera.pos = Vector.new 1000,1000,-2000

$step = 5
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

GL.Disable(GL::CULL_FACE)
GL.PolygonMode(GL::FRONT, GL::LINE)
GL.PolygonMode(GL::BACK, GL::LINE)


$window.display = Proc.new{

	# read mouse for rotation
	x,y = Mouse.get

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

$window.run
