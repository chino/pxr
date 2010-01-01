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

def set_view mesh
	GL.MatrixMode(GL::PROJECTION)
	GL.LoadIdentity
	GLU.Perspective(45.0, $width/$height, 10.0, 100000.0)
	GL.MatrixMode(GL::MODELVIEW)
	GL.LoadIdentity
	# invert the z axis
	GL.Scale(1,1,-1)
	# look at last vert from location of first vert
	x1,y1,z1 = mesh.verts[0][:vector]
	x2,y2,z2 = mesh.verts.last[:vector]
	GLU.LookAt( 
		# position
		x1, y1, z1,

		# look at
		x2, y2, z2, 

		# up vector
		0, 1, 0 
	)
end

# GLUT callbacks

display = Proc.new {
	GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT);
	GL.ClearDepth(1.0)
	set_view $level
	$level.draw
	GL.Flush
	GLUT.SwapBuffers
	GLUT.PostRedisplay
}

keyboard = Proc.new { |key,x,y|
    case (key)
        when 27 # ESCAPE
        	exit 0
    end
}

reshape = Proc.new { |w,h|
	h = 1 if h == 0
	$width, $height = w,h
	GL.Viewport(0, 0, $width, $height);
	set_view $level
}

# setup GLUT
GLUT.Init
GLUT.InitDisplayMode(GLUT::DOUBLE | GLUT::RGB | GLUT::DEPTH)
GLUT.InitWindowSize($width, $height)
GLUT.CreateWindow($title)

# glut callbacks
GLUT.ReshapeFunc(reshape)
GLUT.DisplayFunc(display)
GLUT.KeyboardFunc(keyboard)

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
$level = FsknMx.new("ship.mxv")

# start main loop
GLUT.MainLoop()

