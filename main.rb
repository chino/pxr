#!/usr/bin/env ruby
require "rubygems"
require "opengl"
require "fsknmx"

# globals
$level = nil

# window settings
$title = "Level Viewer"
$width = 640
$height = 480

# look at something in a sane way
def look_at position, lookat
	GL.MatrixMode(GL::MODELVIEW)
	GL.LoadIdentity
	GL.Scale(1,1,-1)
	GLU.LookAt( 
		position[0], position[1], position[2],
		lookat[0], lookat[1], lookat[2],
		0, 1, 0	# up vector
	)
end

# reshape viewport
def reshape w, h
	h = 1 if h == 0
	$width, $height = w,h
	GL.Viewport(0, 0, $width, $height);
	GL.MatrixMode(GL::PROJECTION)
	GL.LoadIdentity
	GLU.Perspective(45.0, $width/$height, 10.0, 100000.0)
end

# setup GLUT
GLUT.Init
GLUT.InitDisplayMode(GLUT::DOUBLE | GLUT::RGB | GLUT::DEPTH)
GLUT.InitWindowSize($width, $height)
GLUT.CreateWindow($title)
GLUT.ReshapeFunc(Proc.new {|w,h| reshape w, h })
GLUT.DisplayFunc(Proc.new {
	GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT);
	GL.ClearDepth(1.0)
	$level.draw
	GL.Flush
	GLUT.SwapBuffers
	GLUT.PostRedisplay
})
GLUT.KeyboardFunc(Proc.new {|key,x,y|
	case (key)
        when 27 # ESCAPE
        	exit 0
	else
		puts key
	end
})

# setup GL
GL.Enable(GL::DEPTH_TEST)
GL.DepthFunc(GL::LESS) 
GL.ShadeModel(GL::SMOOTH)
GL.Enable(GL::CULL_FACE)
GL.CullFace(GL::BACK)
GL.FrontFace(GL::CW)
GL.Disable(GL::LIGHTING)

# wireframe mode
#GL.PolygonMode(GL::FRONT, GL::LINE)
#GL.PolygonMode(GL::BACK, GL::LINE)

# load level
$level = FsknMx.new "ship.mxv"

# setup initial shape
reshape $width, $height

# look at last vert from location of first vert
look_at(
	$level.verts.first[:vector], 
	$level.verts.last[:vector]
)

# start main loop
GLUT.MainLoop

