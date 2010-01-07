#!/usr/bin/env ruby
require "#{File.dirname __FILE__}/lib/headers"

$window  = Window.new("Model Viewer", 640, 480)
$ship    = FsknMx.new "data/sxcop400.mxa"
$lines   = Lines.new

$window.display = Proc.new{
	x,y = Mouse.get
	$ship.rotate x,y
	$ship.pos.z = +500
	$ship.goto
	$ship.draw
}

$window.run
