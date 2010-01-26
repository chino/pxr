#!/usr/bin/env ruby
require "#{File.dirname __FILE__}/lib/headers"

$window  = Window.new("Model Viewer", 640, 480)
$ship    = FsknMx.new "data/sxcop400.mxa"
$lines   = Lines.new

$r=0
$window.display = Proc.new{
	GL.MatrixMode GL::MODELVIEW
	GL.LoadIdentity
	GL.Scale 1, 1, -1
	GL.Translate 0, 0, 150
	GL.Rotate $r+=1, 0, 1, 0 
	$ship.draw
	$lines.draw
}

$window.run
