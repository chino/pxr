#!/usr/bin/env ruby
require "#{File.dirname __FILE__}/lib/headers"

$window  = Window.new("Model Viewer", 640, 480)
$ship    = FsknMx.new "data/sxcop400.mxa"
$lines   = Lines.new

$window.display = Proc.new{
	GL.MatrixMode(GL::MODELVIEW)
	GL.LoadIdentity
	GL.Scale(1,1,-1)
	GL.Translate(0,0,200)
	GL.Rotate(140,0,-1,0)
	GL.Rotate(30,1,0,0)
	$ship.draw
	$lines.draw
}

$window.run
