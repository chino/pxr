if ARGV.empty?
	puts "Pass a files to render"
	exit
end

$movement = Vector.new 0,0,0
$inputs = Input.new($options)
$inputs.keyboard = Proc.new{|key,unicode,pressed|
	released = !pressed
	begin
		k = key.chr.downcase
	rescue
		k = key
	end
	#puts "k=>#{k.inspect}, u=>#{unicode}"
	#puts "key #{k} #{pressed ? 'pressed':'released'}, binded to #{b}"
	b = $bindings[k]
	if b
		case b
		when :right    then pressed ? $movement.x =  1 : $movement.x = 0 
		when :left     then pressed ? $movement.x = -1 : $movement.x = 0 
		when :up       then pressed ? $movement.y =  1 : $movement.y = 0 
		when :down     then pressed ? $movement.y = -1 : $movement.y = 0 
		when :forward  then pressed ? $movement.z = -1 : $movement.z = 0 
		when :back     then pressed ? $movement.z =  1 : $movement.z = 0
		else puts "unknown key action #{b}"
		end
	end
}

$x = 0
def handle_mouse

	# get accumulated mouse movement
	$x, y = $inputs.mouse_get

	# up/down (y) on mouse means rotate on x
	# left/right (x) on mouse means rotate on y
	# so here we flip the x, y inputs for that reason
	v = Vector.new( y, $x )

	# ignore insignificant values
	#return unless v.has_velocity?

	# apply mouse accelleration
	v += v * $turn_accell * -1

	# apply movement to rotation velocity
	$player.apply_relative_torque v

end

def handle_keyboard

	return unless $movement.has_velocity?

	# convert movement into world coordinates
	movement = $player.orientation.vector($movement)

	# apply movement accelleration
	movement += movement * $move_accell

	# apply movement to velocity
	$player.apply_central_force movement

end

$inputs.on_poll Proc.new{
	handle_mouse
	handle_keyboard
}

$position = Vector.new
$render = Render.new($options)
ARGV.each do |path|
	if path =~ /menu.mx$/
		puts "something wrong with menu.mx (skipping...)"
		next
	end
	file = File.basename(path)
	model = Model.new({ :file => file })
	r1 = begin; $render.models.last.radius.to_i * 2
				rescue; puts "defaulted r1 to 200"; 200; end
	r2 = begin; r2 = model.radius.to_i * 2
				rescue; puts "defaulted r2 to 200"; 200; end
	$position += Vector.new(r1+r2,0,0)
	model.body = Physics::SphereBody.new({
		:pos => $position,
		:radius => model.radius
	})
	puts "loading #{file} at position #{$position} radius = #{r2}"
	$render.models << model
end

$world = PhysicsBullet::World.new
$player = Physics::SphereBody.new({
	:pos => Vector.new(0,0,100),
	:linear_damping => $linear_damping,
	:angular_damping => $angular_damping
})
$world.add $player

loop do
	$world.update
	$inputs.poll
	$render.draw( $player.pos, $player.orientation ) do
		$render.models.map do |m|
			m.body.render_radius true
		end if $options[:debug]
	end
end
