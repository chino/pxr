#!/usr/bin/env ruby
require "#{File.dirname __FILE__}/lib/headers"
$window  = Window.new("Model Viewer", 640, 480)
$ship    = FsknMx.new "data/sxcop400.mxa"
$level   = FsknMx.new "data/ship.mxv"
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
$rotation = 0
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
	$level.draw

	# draw ship
	GL.MatrixMode(GL::MODELVIEW)
	GL.LoadIdentity
	GL.Scale(1,1,-1)
	GL.Rotate($rotation+=1,0,0,1)
	GL.Translate(0,-100,200)
	$ship.draw
}
$window.run
