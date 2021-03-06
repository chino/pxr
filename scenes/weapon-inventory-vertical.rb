
####################################
# Physics
####################################

$world = Physics::World.new

def sphere_body s={}
	body = Physics::SphereBody.new(s)
	$world.bodies.add body
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
	v = Vector.new( $inputs.mouse_get )
	return unless v.has_velocity?

	# apply mouse accelleration
	v += v * $turn_accell

	# apply movement to velocity
	$player.angular_velocity -= v

end

def handle_keyboard

	return unless $movement.has_velocity?

	# convert movement into world coordinates
	movement = $player.orientation.vector($movement)

	# apply movement accelleration
	movement += movement * $move_accell

	# apply movement to velocity
	$player.linear_velocity += movement

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
	vel = orientation.vector( Vector.new(0,0,-100) )
	m = Model.new({
		:file => "ball1.mx", 
		:scale => Vector.new(0.5,0.5,0.5),
		:body => sphere_body({
			:pos => pos,
			:linear_velocity => vel,
			:linear_damping => 0,
			:angular_velocity => Vector.new(10,10,10),
			:angular_damping => 0,
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
	:pos => Vector.new(-550.0,-500.0,4600.0),
	:linear_damping => $linear_damping,
	:angular_damping => $angular_damping,
	:type => PLAYER,
	:mask => [BULLET,PLAYER,PICKUP]
})
$player.rotate 180,0,0

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

if $options[:debug]

def collide_body_with_plane body, normal
	m = normal.dot( body.linear_velocity ) # ammount of movement towards plane
	vtp = normal * m                # ammount of velocity towards plane
	vtp += vtp * body.bounce        # multiply velocity by bounce
	body.linear_velocity -= vtp            # apply force to the velocity
end

$level_bsp = FsknBsp.new("data/models/ship.bsp")
rv,node,$in_group = $level_bsp.point_inside_groups?($player.pos, $player.radius)
$level_bsp_update = Proc.new{

	# my position after movement
	stop = $player.pos + $player.linear_velocity + 10

	# I'm initially outside the level
	if $in_group == -1

		# does my movement put me inside the level ?
		rv,node,$in_group = $level_bsp.point_inside_groups?( stop, $player.radius )

		# I'm inside the level now
		if $in_group != -1
			puts "hit wall at group #{$in_group} node #{node} from outside"
			# need to walk tree backwards to find proper collision plane
			#collide_body_with_plane $player, node.normal*-1
			$render.models << $level_bsp.render_node(node) if $options[:debug]
		end

		#
		next false
	end

	# am I still in the same group ?
	in_same_group,node1 = $level_bsp.point_inside_group?( stop, $in_group, $player.radius )
	next false if in_same_group

	# am I in a new group or outside level ?
	old_group = $in_group
	rv,node2,$in_group = $level_bsp.point_inside_groups?( stop, $player.radius )

	# moved to a new group
	if $in_group != -1
		puts "moved to new level group #{$in_group}"
		next false
	end

	# we hit the wall
	$in_group = old_group

	# find out where and when we collided
	unless $level_bsp.ray_collide_group( $player, $in_group )
		puts "point check says I left level but ray check says I didn't collide" if x == 1
		next false
	end
	p = $level_bsp.collide_point
	n = $level_bsp.collide_node
	unless p and n
		puts "I collided with level but collide point/node are false"
		next false
	end

	# do collision to push player back into inside
	collide_body_with_plane $player, n.normal

=begin
	# debug stuff
	d = n.distance - $player.radius
	puts "collided #{p} #{n} #{n.normal} #{d}"
	$render.models << $level_bsp.render_node(node1) if $options[:debug]
	pos = $player.pos.dup
	pos.x *= -1
	$render.models << Line.new({:lines => [[
		pos.to_a,
		(pos + (node1.normal * 100)).to_a
	]]}) if $options[:debug]
=end

	next true
}

$world.callback = Proc.new{
	$level_bsp_update.call
}

end

$level = Model.new({ :file => "ship.mxv" })
$render.models << $level

if $options[:debug]
	$render.models << Lines.new({:scale => Vector.new(100000,100000,100000)})
	$render.models << $level.mesh.normal_rendering
end

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
		y = 10
		@weapons.each do |weapon,ammo|
			Font.new.render ammo.to_s, 520, y, Color::GREEN unless ammo == -1
			y += 25
		end
	end
	def draw_weapons
		pos = Vector.new 760,-580,-900
		GL.Clear(GL::DEPTH_BUFFER_BIT)
		GL.PushMatrix
		@weapons.each do |weapon,ammo|
			GL.LoadIdentity
			model = get_model weapon
			$render.load_matrix( pos, model.orientation )
			model.draw 
			pos.y += 60
		end
		GL.PopMatrix
	end
	def get_model weapon
		file = @files[weapon]
		model = @models[file]
		return model unless model.nil?
		body =	Physics::SphereBody.new
		body.rotate(-90,0,0)
		@models[file] = Model.new({ :file => file, :body => body })
	end
end
$inventory = Inventory.new
$inventory.set :trojax,  2000
$inventory.set :sussgun, 2000
$inventory.set :titan
$render.ortho_models << $inventory

####################################
# Main Loop
####################################

loop do
	process_bullets
	$inputs.poll
	$world.update
	$update_network.call
	$picmgr.pump
	$render.draw( $player.pos, $player.orientation ) do
		if $options[:debug]
			$world.bodies.each{|body| body.render_radius }
		end
		$inventory.draw_weapons
	end
	SDL::WM.setCaption "PXR - FPS: #{$render.fps}", 'icon'
end
