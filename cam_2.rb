#!/usr/bin/env ruby
require "#{File.dirname __FILE__}/lib/headers"

$window  = Window.new("Model Viewer", 640, 480)

# glut.init was crashing if i passed in argv[1] ???
$host,$port = (ARGV[0]||"").split(":")
$port = $port || 2300
$network = Network.new( $host, $port ) if ARGV.length > 0

# this is not working yet
$image = Image.new("data/excop.png")
class FsknMx2 < FsknMx
	def draw
		$image.bind
		super
		$image.unbind
	end
end
# uncomment to see the image!
# $image.image.display

$ship    = FsknMx2.new("data/sxcop400.mxa")
$ship2   = FsknMx.new("data/nbia400.mxa")
$ship3   = FsknMx.new("data/nbia400.mxa")
$level   = FsknMx.new("data/ship.mxv")
$lines   = Lines.new
$camera  = View.new

$fusionfarm = D1rdl.new("data/fusnfarm.rdl")

$step = 30
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
			$ship3.pos = Vector.new px,py,pz
			$ship3.orientation = Quat.new ox,oy,oz,ow
		end
		# send current data
		if (Time.now - $last_send).to_i > (60/10)
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
		end
	end
	
	# read mouse for rotation
	x,y = Mouse.get

	# apply rotation
	$camera.rotate x, y

	# apply movement
	$camera.move $movement

	# modify coordinate system based on camera position
	$camera.load_matrix

	# draw level at origin
	$level.draw

	# draw the "Kiln's Fusion Farm" level
	$fusionfarm.pos = Vector.new 0,0,-200
	GL.PushMatrix
	$fusionfarm.mult_matrix
	$fusionfarm.draw
	GL.PopMatrix

	# draw lines at origin
	$lines.draw

	# draw ship
	$ship.pos = Vector.new 500,-500,-5000
	GL.PushMatrix
	$ship.mult_matrix
#	$image.bind
	$ship.draw
#	$image.unbind
	GL.PopMatrix

	# draw ship2
	$ship2.pos = Vector.new 550,-500,-5000
	GL.PushMatrix
	$ship2.mult_matrix
	$ship2.draw
	GL.PopMatrix

	# draw ship3
	GL.PushMatrix
	$ship3.mult_matrix
	$ship3.draw
	GL.PopMatrix
}

$window.run
