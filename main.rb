#!/usr/bin/env ruby
require "rubygems"
require "opengl"
require "fsknmx"

# window settings
$width, $height = 640, 480

def set_view
	GL.MatrixMode(GL::PROJECTION)
	GL.LoadIdentity
	GLU.Perspective(45.0, $width/$height, 10.0, 32767.0)
	GL.MatrixMode(GL::MODELVIEW)
	# attempt to look at first vert
	v = $level.verts[0]
	x,y,z = v
	GLU.LookAt( 
		x+10,y+10,z+10, 
		x,y,z,
		0,0,0 
	)
	GL.Scale(1,1,-1)
end

def draw_poly poly
	GL.Begin(GL::POLYGON)
	poly.each do |index|
		x,y,z = $level.verts[index]
		GL.Vertex3f( x, y, z )
	end
	GL.End
end

def draw_level
	$level.triangles.each do |triangle|
		draw_poly triangle
	end
end

# GLUT callbacks

display = Proc.new {
	GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT);
	GL.ClearDepth(1.0)
	set_view
	draw_level
	GL.Flush
	GLUT.SwapBuffers
	GLUT.PostRedisplay
}

keyboard = Proc.new { |key,x,y|
    case (key)
        when 27 # ESCAPE
        	exit 0
        when 'f'[0]
	        GLUT.ReshapeWindow(640,480)
    end
}

reshape = Proc.new { |w,h|
	h = 1 if h == 0
	$width, $height = w,h
	GL.Viewport(0, 0, $width, $height);              
	# Re-initialize the window (same lines from InitGL)
	GL.MatrixMode(GL::PROJECTION);
	GL.LoadIdentity;
	GLU.Perspective(45.0, $width/$height, 0.1, 100.0);
	GL.MatrixMode(GL::MODELVIEW);
}

# setup GLUT
GLUT.Init
GLUT.InitDisplayMode(GLUT::DOUBLE | GLUT::RGB | GLUT::DEPTH)
GLUT.InitWindowSize($width, $height)
GLUT.CreateWindow($0)

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
GL.PolygonMode(GL::FRONT, GL::LINE)
GL.PolygonMode(GL::BACK, GL::LINE)

# load level
puts "loading level"
$level = FsknMx.new("ship.mxv")

# start main loop
GLUT.MainLoop()

