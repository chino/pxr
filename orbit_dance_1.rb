#!/usr/bin/env ruby
require "#{File.dirname __FILE__}/lib/headers"

$window  = Window.new("Model Viewer", 640, 480)
$ship    = FsknMx.new "data/sxcop400.mxa"
$lines   = Lines.new

$rx=0
$ry=0
def draw_ship distance
	GL.Rotate $rx+=0.05, 0, 1, 0 
	GL.Rotate $ry+=0.05, 1, 0, 0 
	GL.Translate 0, 0, distance
	$ship.draw
	$lines.draw
end

$window.display = Proc.new{
	GL.MatrixMode GL::MODELVIEW
	GL.LoadIdentity
	GL.Scale 1, 1, -1
	z = 2000
	while (z -= 100) > 0
		draw_ship z
	end
}

$window.run
