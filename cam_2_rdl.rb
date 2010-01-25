#!/usr/bin/env ruby
require "#{File.dirname __FILE__}/lib/headers"

$window  = Window.new("Model Viewer", 640, 480)
$fusionfarm = D1rdl.new("data/fusnfarm.rdl")
$neptune = D1rdl.new("data/neptune.rdl")
$camera  = View.new

$step = 3
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

	# Use wireframe mode until we have proper lighting
	GL.PolygonMode(GL::FRONT, GL::LINE)
	GL.PolygonMode(GL::BACK, GL::LINE)

	# draw the "Kiln's Fusion Farm" level
	$fusionfarm.pos = Vector.new 0,0,-200
	GL.PushMatrix
	$fusionfarm.mult_matrix
	$fusionfarm.draw
	GL.PopMatrix

	# draw the "Neptune" level
	$neptune.pos = Vector.new 0,0,-700
	GL.PushMatrix
	$neptune.mult_matrix
	$neptune.draw
	GL.PopMatrix
}

$window.run
