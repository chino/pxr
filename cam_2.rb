#!/usr/bin/env ruby
require "#{File.dirname __FILE__}/lib/headers"

$window  = Window.new("Model Viewer", 640, 480)
$ship    = FsknMx.new("data/sxcop400.mxa")
$ship2   = FsknMx.new("data/nbia400.mxa")
$level   = FsknMx.new("data/ship.mxv")
$camera  = View.new

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

$window.display = Proc.new{
	# read mouse for rotation
	x,y = Mouse.get

	# apply rotation
	$camera.rotate x, y

	# apply movement
	$camera.move $movement

	# modify coordinate system based on camera position
	$camera.load_matrix

	# draw level
	$level.pos = Vector.new 0,0,0
	GL.PushMatrix
	$level.mult_matrix
	$level.draw
	GL.PopMatrix

	# draw ship
	$ship.pos = Vector.new 500,-500,-5000
	GL.PushMatrix
	$ship.mult_matrix
	$ship.draw
	GL.PopMatrix

	# draw ship2
	$ship2.pos = Vector.new 550,-500,-5000
	GL.PushMatrix
	$ship2.mult_matrix
	$ship2.draw
	GL.PopMatrix
}

$window.run
