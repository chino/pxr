#!/usr/bin/env ruby
require "rubygems"
require "opengl"
require "fsknmx"

# input settings
$move_accel = 6.0

# window settings
$title = "Level Viewer"
$width = 640
$height = 480

# globals
$level = nil
$rotation_y = 0
$position_x = 0
$position_z = 0

# reshape viewport
def reshape w, h
	h = 1 if h == 0
	$width, $height = w,h
	GL.Viewport(0, 0, $width, $height);
	GL.MatrixMode(GL::PROJECTION)
	GL.LoadIdentity
	GLU.Perspective(45.0, $width/$height, 10.0, 100000.0)
end

def update_position
	GL.MatrixMode(GL::MODELVIEW)
	GL.LoadIdentity
	GL.Scale(1,1,-1)
	GL.Rotatef((360.0-$rotation_y),0,1,0) # rotate scene on y axis from x axis input
	GL.Translatef( -$position_x, 600, -$position_z ) # Translate The Scene Based On Player Position
	#puts "x: #{-$position_x}, y: #{-$position_z}"
end

# setup GLUT
GLUT.Init
GLUT.InitDisplayMode(GLUT::DOUBLE | GLUT::RGB | GLUT::DEPTH)
GLUT.InitWindowSize($width, $height)
GLUT.CreateWindow($title)
GLUT.ReshapeFunc(Proc.new{|w,h| reshape w, h })
$last_time = 0
$frames = 0
def post_frames
	$frames += 1
	t = Time.now
	seconds = (t - $last_time).to_i
	return unless seconds >= 1
	$last_time = t
	fps = $frames / seconds
	$frames = 0
	GLUT.SetWindowTitle "#{$title} - FPS: #{fps}"
end
GLUT.DisplayFunc(Proc.new{
	GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT);
	GL.ClearDepth(1.0)
	update_position
	$level.draw
	GL.Flush
	GLUT.SwapBuffers
	GLUT.PostRedisplay
	post_frames
})
GLUT.KeyboardFunc(Proc.new{|key,x,y|
	#puts "key: #{key} pressed @ #{x},#{y}"
	# test ascii value
	case (key)
        when 27 # ESCAPE
        	exit 0
	end
	# test as string
	case (key.chr)
	when 'w'
		$position_x += Math.sin($rotation_y*0.0174532925) * 5.0 * $move_accel;	# Move On The X-Plane Based On Player Direction
		$position_z += Math.cos($rotation_y*0.0174532925) * 5.0 * $move_accel;	# Move On The Z-Plane Based On Player Direction
	when 's'
		$position_x -= Math.sin($rotation_y*0.0174532925) * 5.0 * $move_accel;	# Move On The X-Plane Based On Player Direction
		$position_z -= Math.cos($rotation_y*0.0174532925) * 5.0 * $move_accel;	# Move On The Z-Plane Based On Player Direction
	end
})
GLUT.MouseFunc(Proc.new{|button,state,x,y|
	#puts "mouse button: #{button} #{(state==GLUT::DOWN)?"pressed":"released"} @ #{x},#{y}"
})
$last_x = 0
GLUT.PassiveMotionFunc(Proc.new{|x,y|
	diff_x = x - $last_x
	$last_x = x
	$rotation_y += diff_x
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

# default start point
$position_x = $level.verts.last[:vector][0]
$position_z = $level.verts.last[:vector][2]

# start main loop
GLUT.MainLoop

