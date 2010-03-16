$game  = Game.new("Model Viewer", $options[:width], $options[:height], $options[:fullscreen])

$quad = Quad.new

$time = Time.now.to_f
$wave = Proc.new{
	$time = Time.now.to_f
	$quad.verts.each do |vert|
		vert[:vector][2] = Math.sin vert[:vector][0]+vert[:vector][1]+$time
	end
}

$objects = [$quad,Lines.new]

$camera     = View.new
$camera.pos = Vector.new 3000,0,0
$camera.rotate 0,-90,0

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
