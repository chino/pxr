#!/usr/bin/env ruby
require "rubygems"
require "opengl"
require "fsknmx"

# window settings
$title = "Level Viewer"
$width = 640
$height = 480

def set_view
	GL.MatrixMode(GL::PROJECTION)
	GL.LoadIdentity
	GLU.Perspective(45.0, $width/$height, 10.0, 100000.0)
	GL.MatrixMode(GL::MODELVIEW)
	GL.LoadIdentity
	# invert the z axis
	GL.Scale(1,1,-1)
	# look at last vert from location of first vert
	x1,y1,z1 = $level.verts[0]
	x2,y2,z2 = $level.verts.last
	GLU.LookAt( 
		# position
		x1, y1, z1,

		# look at
		x2, y2, z2, 

		# up vector
		0, 1, 0 
	)
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
    end
}

reshape = Proc.new { |w,h|
	h = 1 if h == 0
	$width, $height = w,h
	GL.Viewport(0, 0, $width, $height);
	set_view
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
puts "loading level"
time = Time.now
$level = FsknMx.new("ship.mxv")
seconds = (Time.now - time)
puts "level loaded in #{seconds} seconds"

#
reshape.call($width,$height)

# start main loop
GLUT.MainLoop()

