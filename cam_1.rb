#!/usr/bin/env ruby
require "#{File.dirname __FILE__}/lib/headers"

$window  = Window.new("Model Viewer", 640, 480)
$ship    = FsknMx.new "data/sxcop400.mxa"
$level   = FsknMx.new "data/ship.mxv"
$camera  = View.new

$window.display = Proc.new{

	# read inputs for movement
	x,y = Mouse.get

	# apply movement
	$camera.rotate x, y

	# modify coordinate system based on camera position
	$camera.load_matrix

	# draw objects
	$level.draw

}

$window.run
