
####################################
# Physics
####################################

$world = PhysicsBullet::World.new
#$world = Physics::World.new

def sphere_body s={}
	body = Physics::SphereBody.new(s)
	$world.add body
	body
end

####################################
# Networking
####################################

def send_my_name
	$network.send_data(
		[Player::NAME].pack('c') + 
		$options[:name]
	)
end

class Player < Network::Player
	UPDATE = 0
	BULLET = 1
	TEXT   = 2
	NAME   = 3
	HIT    = 4
	@@players = {}
	def post_init
		puts "new connection from #{@ip}:#{@port}"
		@name = nil
		send_my_name
	end
	def receive_data data
		type = data.slice!(0..0).unpack('c')[0]

		case type
		when TEXT
			$console.add_line data
		when NAME
			unless @name
				name = data
				if @@players[name] or name == $options[:name]
					$network.send_data(
						[Player::TEXT].pack('c') +
						"Sorry #{name} is already in the game"
					) if $hosting
					return
				end
				@name = name
				puts "connect #{@ip}:#{@port} has set his name to #{@name}"
				$score.set @name, 0
				@model = Model.new({
					:file => "nbia400.mxa",
					:body => sphere_body({
						:type => PLAYER,
						:mask => [BULLET,PLAYER,PICKUP]
					})
				})
				$render.models << @model
				@@players[@name] = @model
			end
		end

		return unless @name or type == NAME

		case type
		when UPDATE
			@model.body.unserialize! data if @model
		when BULLET
			pos_s, orientation_s = data.unpack("a12a8")
			pos = Vector.new
			pos.unserialize! pos_s, :full
			orientation = Quat.new
			orientation.unserialize! orientation_s, :short
			new_bullet( pos, orientation, Proc.new{|bullet,target|
				next unless target == $player
				$score.add @name
				$network.send_data(
					[Player::HIT].pack('c') + 
					@name
				)
			})
		when HIT
			name = data
			if @@players[name] or name == $options[:name]
				$score.add name
			else
				debug "got hit for non player #{name}"
			end
		else
			debug "unknown packet from player #{@id}"
		end
	end
end

$hosting = false
if $options[:peer][:address].nil?
	$hosting = true
	$network = Network::Server.new($options[:port],Player)
	send_my_name
else
	$network = Network::Client.new(
		$options[:peer][:address], 
		$options[:peer][:port], 
		$options[:port],
		Player
	)
end

$last_sent = Time.now
$pps = 1.0/30.0

$update_network = Proc.new {
	if (Time.now - $last_sent).to_f >= $pps
		$network.send_data(
			[Player::UPDATE].pack('c') + 
			$player.serialize
		)
		$last_sent = Time.now
	end
	$network.pump
}

####################################
# Inputs
####################################

$inputs = Input.new($options)

$inputs.mouse_button = Proc.new{|button,pressed|
	next unless pressed
	pos = $player.pos + $player.orientation.vector( Vector.new(0,0,-$player.radius*3) )
	new_bullet( pos, $player.orientation )
	send_bullet( pos, $player.orientation )
}

$movement = Vector.new 0,0,0

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
	if released and b == :type
		$console.typing = !$console.typing
	end
	if pressed and $console.typing
		$console.key_press(unicode != 0 ? unicode : key)
	end
	if not $console.typing and b
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

def handle_mouse

	# get accumulated mouse movement
	x, y = $inputs.mouse_get

	# up/down (y) on mouse means rotate on x
	# left/right (x) on mouse means rotate on y
	# so here we flip the x, y inputs for that reason
	v = Vector.new( y, x )

	# ignore insignificant values
	#return unless v.has_velocity?

	# apply mouse accelleration
	v += v * $turn_accell

	# apply movement to rotation velocity
	$player.rotation_velocity -= v

end

def handle_keyboard

	return unless $movement.has_velocity?

	# convert movement into world coordinates
	movement = $player.orientation.vector($movement)

	# apply movement accelleration
	movement += movement * $move_accell

	# apply movement to velocity
	$player.velocity += movement

end

$inputs.on_poll Proc.new{
	handle_mouse
	handle_keyboard
}


####################################
# Scene
####################################

PLAYER = 2
BULLET = 4
PICKUP = 6

$bullets = []

def process_bullets
	#puts "live bullets #{$bullets.length}" if $bullets.length > 0
	$bullets.dup.each do |bullet|
		if Time.now - bullet[:time] > 5 # seconds
			$world.remove bullet[:model].body
			$render.models.delete bullet[:model]
			$bullets.delete bullet
		end
	end
end

def new_bullet pos, orientation, block=nil
	vel = orientation.vector( Vector.new(0,0,-100000) )
	m = Model.new({
		:file => "ball1.mx", 
		:scale => Vector.new(0.5,0.5,0.5),
		:body => sphere_body({
			:pos => pos,
			:velocity => vel,
			:drag => 0,
			:rotation_velocity => Vector.new(10,10,10),
			:rotation_drag => 0,
			:type => BULLET,
			:mask => [PLAYER],
			:on_collision => Proc.new{|bullet,target|
				block.call bullet, target if block
				# TODO need to destroy bullet
				next true
			}
		})
	})
	$render.models << m
	$bullets << {:time => Time.now, :model => m}
	m
end

def send_bullet pos, orientation
	$network.send_data(
		[Player::BULLET].pack('c') +
		pos.serialize(:full) + 
		orientation.serialize(:short)
	)
end

$render = Render.new($options)

$player = sphere_body({
#	:pos => Vector.new(-550.0,-500.0,4600.0),
	:pos => Vector.new(0,0,0),
	:orientation => Quat.new.rotate!(0,180,0),
	:drag => $move_drag,
	:rotation_drag => $turn_drag,
	:rotation_velocity => Vector.new(0,0,0),
	:type => PLAYER,
	:mask => [BULLET,PLAYER,PICKUP]
})

$cross_hair = Line.new({
	:pos   => Vector.new($render.width/2,$render.height/2,0),
	:scale => 10,
	:lines => [ [[-1,0],[1,0]], [[0,-1],[0,1]], ]
})
=begin
pointer = CrossHairCircle.new( 100, $render.surface )
$cross_hair = Point.new({
	:pos    => Vector.new($render.width/2,$render.height/2,0),
	:points => [ [[0,0],nil,pointer,true] ],
	:size   => pointer.size
})
=end
$render.ortho_models << $cross_hair
$render.models << Model.new({
	:file => "nbia400.mxa", 
	:body => sphere_body({
		:pos => Vector.new(-400.0,-500.0,5000.0), 
		:type => PLAYER,
		:mask => [BULLET,PLAYER,PICKUP]
	})
})

$render.models << Model.new({
	:file => "xcop400.mxa",
	:body => sphere_body({
		:pos => Vector.new(-600.0,-500.0,5000.0),
		:type => PLAYER,
		:mask => [BULLET,PLAYER,PICKUP]
	})
})

# notes
#		collision_point = center of body at moment of collision hence
#              wall = collision_point + (node.normal * radius)

# forsaken globals
$global_scale = 0.25
$collision_fudge = 10 * $global_scale

def collide_body_with_plane_fskn body, node, collision_point


## figure out where you end up if your velocity slides you along wall from collision point

	# from OneGroupPolyCol in collisions.c
	# enemy collision detection here would detect and respond
	# background object collision detection as well
	# but bg colls would not run the following code
	# the following code code runs if RayCollide hits bsp walls
	# but again not if bg col happens

	e = collision_point + body.velocity
	nDOTe =	 e.dot node.normal
	target_distance = nDOTe + node.distance
	d = target_distance.abs + $collision_fudge
	dn = node.normal * d
	target_pos = e + dn # position after sliding

## appears to correct body start position in case your past the wall still
## this has to be done probably because we want to move far enough away
## that we end up hitting the next wall in a corner
## because RayCollide will always return the first wall it finds we are touching
## which is dependant on the order of the bsp nodes
## so if we move lightly away then next loop we hit the next one
## so we basically jump back and forth between walls

	# from BackgroundCollide in collisions.c
	begin # protect from sqrt error in .length
		dist_to_wall = (collision_point - body.pos).length
	rescue
		dist_to_wall = 0
	end
	# skipping all the group portal detection
	# further down in BackgroundCollide response
	dir = body.velocity.normalize
	velocity_towards_wall = dir.dot node.normal
	sliding_along_wall = velocity_towards_wall == 0
	# convert $collision_fudge into percentage of velocity_towards_wall
	# so that we can fudge the direction properly ?
	impact_offset = if sliding_along_wall
										2 * dist_to_wall # wouldn't this always be 0 ?
									else
										$collision_fudge / -velocity_towards_wall
									end
	if dist_to_wall > impact_offset
		pos = collision_point - (dir * impact_offset)
	else
		pos = body.pos
	end

## snap to protected-start-position and set velocity to land on desired slide-along-wall position

	# from ProcessShips in ships.c 
	body.pos = pos
	body.velocity = target_pos - pos

end

def collide_body_with_plane_my_way_with_fudge body, node, point

collision_fudge = $collision_fudge * 10

	m = node.normal.dot body.velocity # movement towards plane
#puts "n=#{node.normal}"
#puts "v=#{body.velocity}"
#puts "m=#{m}"

if m - collision_fudge > 0
#	puts "we are already moving away from plane, m=#{m}"
	return
#elsif m == 0
#	puts "we are moving along plane"
end

	v = node.normal * m    # velocity towards plane
	v += v * body.bounce   # increase by bounce factor
	body.velocity -= v     # remove it

	# stop colliding with this plane on next loop
	# so that we can run 3 times and collide with a corner
	fudge = node.normal * collision_fudge
	body.pos += fudge

m = node.normal.dot body.velocity
#puts "t=#{vtp}"
#puts "v-t=#{body.velocity}"
#puts "m=#{m}"

if m + collision_fudge < 0
#	puts "we are still moving towards plane"
#	exit
end

end

def collide_body_with_plane_my_way body, node, point

	m = node.normal.dot body.velocity # movement towards plane

	if m > 0
#		puts ":: we are already moving away from plane, m=#{m}"
#		exit
		return
	elsif m == 0
#		puts ":: we are moving along plane"
		m = -1 # push away
		#return
	end

	v = node.normal * m    # velocity towards plane
	v += v * body.bounce   # increase by bounce factor
	body.velocity -= v     # remove it

	# check
	m = node.normal.dot body.velocity
	if m < 0
#		puts ":: we are still moving towards plane"
	end

end

=begin
# render a single triangle
$render.models << Triangle.new({
	:verts => [
		{:vector => [-100,0,0], :rgba => [255,0,0,0], :transparencies => false},
		{:vector => [0,100,0], :rgba => [0,255,0,0], :transparencies => false},
		{:vector => [100,0,0], :rgba => [0,0,255,0], :transparencies => false}
	]
})
=end

=begin
$level_bsp = FsknBsp.new("data/models/ship.bsp")
$world.callback = Proc.new{
	$level_bsp.collide( $world.bodies ) do |body,node,point|
		collide_body_with_plane_my_way body,node,point
	end
}
=end

# load the level
$level = Model.new({ :file => "ship.mxv" })
$render.models << $level
$world.add $level

=begin
# was trying to load each triangle individually
# but to much rendering overhead right now 
$level.mesh.primitives.each do |p|

	$render.models << Triangle.new({
		:verts => [
			$level.mesh.verts[ p[:verts][0] ],
			$level.mesh.verts[ p[:verts][1] ],
			$level.mesh.verts[ p[:verts][2] ]
		],
		:texture => nil, #p[:texture],
		:body => sphere_body({
			:mass => 1,
			:drag => 0.085,
			:rotation_drag => 0.085,
			:radius => p[:radius],
			:pos => Vector.new( -p[:pos][0], p[:pos][1], p[:pos][2] ),
			:orientation => Quat.new
		})
	})

end
=end

# render x/y/z axis at origin
if $options[:debug]
	$render.models << Lines.new({:scale => Vector.new(100000,100000,100000)})
	$render.models << $level.mesh.normal_rendering
end

# load pickup positions
pickups = FsknPic.new("data/models/ship.pic").pickups
pickups.each do |pickup|
	pickup.body.type = PICKUP
	pickup.body.mask = [PLAYER]
end
$picmgr = PickupManager.new({
	:world => $world,
	:render => $render,
	:pickups => pickups,
	:regen_time => 10, # seconds
	:on_pickup => Proc.new{|pickup,player|
		puts "player picked up pickup"
		true # allow to pickup
	}
})

####################################
# UI
####################################

$console = Console.new $options[:name], 5, 5, 100, 100 # bottom { x, y }, width, height
$console.on_message = Proc.new{|text|
	$network.send_data(
		[Player::TEXT].pack('c') +
		text
	)
}

$score = Score.new({:height => $render.height})
$score.set $options[:name], 0

$render.ortho_models << $console
$render.ortho_models << $score

####################################
# on screen weapon inventory
####################################

class Inventory
	def initialize
		@files   = {
			:trojax  => "troj.mx",
			:sussgun => "sus.mx",
			:titan   => "titan.mx"
		}
		@models  = {}
		@weapons = {}
	end
	def set weapon, ammo=-1
		@weapons[ weapon.to_sym ] = ammo
	end
	def draw mode=:both
		draw_text
	end
	def draw_text
		x = 10
		@weapons.each do |weapon,ammo|
#			Font.new.render ammo.to_s, x, 10, Color::GREEN unless ammo == -1
			x += 110
		end
	end
	def draw_weapons
		pos = Vector.new -600,-580,-900
		GL.Clear(GL::DEPTH_BUFFER_BIT)
		GL.PushMatrix
		@weapons.each do |weapon,ammo|
			GL.LoadIdentity
			model = get_model weapon
			$render.load_matrix( pos, model.orientation )
			model.draw 
			pos.x += 300
		end
		GL.PopMatrix
	end
	def get_model weapon
		file = @files[weapon]
		model = @models[file]
		return model unless model.nil?
		body =	Physics::SphereBody.new({:orientation => Quat.new.rotate(-90,0,0)})
		@models[file] = Model.new({ :file => file, :body => body })
	end
end
$inventory = Inventory.new
$inventory.set :trojax,  2000
$inventory.set :sussgun, 2000
$inventory.set :titan
#$render.ortho_models << $inventory

####################################
# Main Loop
####################################

# request all the lines from bullet so 
# we can create display lists for them 
PhysicsBullet::physics_debug_draw if $options[:debug]

loop do
	process_bullets
	$inputs.poll
	$update_network.call
	$world.update
	$picmgr.pump
	$render.draw( $player.pos, $player.orientation ) do
		if $options[:debug]
			$world.draw_lines
			$world.bodies.each{|body| body.render_radius }
		end
		#$inventory.draw_weapons
	end
	SDL::WM.setCaption "PXR - FPS: #{$render.fps}", 'icon'
end
