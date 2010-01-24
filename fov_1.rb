#!/usr/bin/env ruby
require "#{File.dirname __FILE__}/lib/headers"

$window  = Window.new("Model Viewer", 640, 480)
$ship    = FsknMx.new "data/sxcop400.mxa"
$level   = FsknMx.new "data/ship.mxv"
$camera  = View.new

$fov = 100
def fov_cycle
	$fov+=1
	$fov = 0 if $fov > 360
	puts "fov set to #{$fov}"
	GL.MatrixMode(GL::PROJECTION)
	GL.LoadIdentity
	GLU.Perspective($fov, $window.aspect, 10.0, 100000.0)
end

$step = 30
$movement = Vector.new 0,0,0
$bindings = {
	"w" => :forward,
	"s" => :back,
	"e" => :up,
	"d" => :down,
	"f" => :left,
	"g" => :right,
	"1" => :fov_cycle
}
$window.keyboard = Proc.new{|key,x,y,pressed|
	k = key.chr.downcase
	b = $bindings[k]
	#puts "key #{k} #{pressed ? 'pressed':'released'}, binded to #{b}"
	case b
	when :right then pressed ? $movement.x += $step : $movement.x = 0 
	when :left then pressed ? $movement.x -= $step : $movement.x = 0 
	when :up then pressed ? $movement.y += $step : $movement.y = 0 
	when :down then pressed ? $movement.y -= $step : $movement.y = 0 
	when :forward then pressed ? $movement.z += $step : $movement.z = 0 
	when :back then pressed ? $movement.z -= $step : $movement.z = 0
	when :fov_cycle then fov_cycle
	else puts "unknown key binding #{k}"
	end
}

$window.display = Proc.new{

	# read mouse for rotation
	x,y = Mouse.get

	# apply rotation
	$camera.rotate x, y

	# apply movement
	$camera.move $movement

	# modify coordinate system based on camera position
	$camera.load_matrix

	# draw objects
	$level.draw
}

$window.run
