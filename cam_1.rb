#!/usr/bin/env ruby
require "#{File.dirname __FILE__}/lib/headers"

$window  = Window.new("Model Viewer", 640, 480)
$ship    = FsknMx.new "data/sxcop400.mxa"
$level   = FsknMx.new "data/ship.mxv"
$camera  = Camera.new $ship

$window.display = Proc.new{
	$level.draw
	x,y = Mouse.get
	$ship.rotate x,y
	$camera.update
}

$window.run
