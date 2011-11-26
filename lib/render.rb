require "rubygems"
require "sdl"
require "opengl"
class Render
	attr_accessor :models, :ortho_models, :fps, :width, :height, :depth, :fov, :surface
	def initialize s
		@models = []
		@ortho_models = []
		@fps = 0
		@frames = 0
		@last_frame = 0
		@depth = s[:depth] || 32
		@fov = s[:fov].to_f || 70.0
		@fullscreen = s[:fullscreen]
		@width = s[:width].to_f
		@height = s[:height].to_f
		SDL.init(SDL::INIT_VIDEO)
		SDL::Event2.enable_unicode
		SDL.setGLAttr(SDL::GL_DOUBLEBUFFER,1)
		flags = SDL::OPENGL
		flags |= SDL::FULLSCREEN if @fullscreen
		@surface = SDL.setVideoMode( @width, @height, @depth, flags )
		reshape( @width, @height )
		GL.Enable(GL::DEPTH_TEST)
		GL.DepthFunc(GL::LESS) 
		GL.ShadeModel(GL::SMOOTH)
		GL.Disable(GL::CULL_FACE)
		GL.CullFace(GL::BACK)
		GL.FrontFace(GL::CW)
		GL.Disable(GL::LIGHTING)
		GL.Hint(GL::PERSPECTIVE_CORRECTION_HINT, GL::NICEST)
	end
	def reshape width=640, height=480
		@width = width.to_f
		@height = height.to_f
		GL.Viewport(0, 0, @width, @height);
		GL.MatrixMode(GL::PROJECTION)
		GL.LoadIdentity
		aspect = @width / @height
		GLU.Perspective(@fov, aspect, 10.0, 100000.0)
		GL.MatrixMode(GL::MODELVIEW)
	end
	def wireframe
		GL.PolygonMode(GL::FRONT, GL::LINE)
		GL.PolygonMode(GL::BACK, GL::LINE)
	end
	def draw pos, orientation, bvh=nil, &block
		GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
		look_at( pos, orientation )
		# old way wasn't good enough
			#models = clip_behind_camera pos, orientation
		# clip by fustrum planes
			models = clip_fustrum @models
		#puts "rendering #{models.length} models"
# clip by occlusion using bvh of level
# doesn't work nice since centers do not see 
# each other but edges of the sphere / mesh do
# also touching any wall causes the ray test
# to fail right away (weird as center is not 
# touching)..  also objects seem to flicker
=begin
		models = models.select do |model|
			next true if model == bvh
			hit = bvh.mesh.ray_cast pos, model.pos
			puts "I can see #{pos}" if not hit
			not hit
		end if bvh
=end
		draw_models( models )
		block.call if block_given?
		draw_ortho if @ortho_models.length > 0
		GL.Flush
		SDL.GLSwapBuffers
		update_fps
	end
	def clip_behind_camera pos, orientation
		plane = Physics::PlaneBody.new({
			:pos => pos,
			:orientation => orientation 
		})
		clip_behind( plane, @models )
	end
	def clip_behind plane, models
		models.select do |model|
			next true if model.radius.nil?
			# edge of sphere towards me
			# accounts for being inside of large objects
			pos = model.pos + (plane.normal * model.radius)
			plane.side( pos ) != :back
		end
	end
	def extract_plane mat, side

		row = {
			:left   =>  1,
			:right  => -1,
			:bottom =>  2,
			:top    => -2,
			:near   =>  3,
			:far    => -3
		}[side]

		scale = (row < 0) ? -1 : 1;
		row = row.abs - 1;
	
		plane = [
			# normal
			mat[3] + scale * mat[row],
			mat[7] + scale * mat[row + 4],
			mat[11] + scale * mat[row + 8],
			# distance
			mat[15] + scale * mat[row + 12]
		]
	
		length = Vector.new(plane).length

		plane = plane.map{|x|x/=length}

		Physics::PlaneBody.new({
			:normal => Vector.new(plane),
			:distance => plane[3]
		})

	end
	def clip_fustrum models

		start = Time.now if $options[:debug]

		mv = GL.GetFloatv GL::MODELVIEW_MATRIX
		pm = GL.GetFloatv GL::PROJECTION_MATRIX
	
		GL.PushMatrix
		GL.LoadMatrixf pm
		GL.MultMatrixf mv
		m = GL.GetFloatv(GL::MODELVIEW_MATRIX).flatten
		GL.PopMatrix

		[:near, :far, :left, :right, :top, :bottom].each do |side|
			models = clip_behind( extract_plane(m, side), models )
			if models.empty?
				puts "no more models left to check after #{side} side"
				break
			end
		end

		if $options[:debug]
			t = Time.now - start
			puts "took #{t}s to clip objects outside of frustrum"
		end

		models

	end
	def draw_models models
		models.each{|model| draw_model( :opaque, model ) }
		set_trans
		models.each{|model| draw_model( :trans, model ) }
		unset_trans
	end
	def draw_model mode, model
		mv = (model.respond_to? :pos and
				 model.respond_to? :orientation)
		if mv
			GL.PushMatrix
			load_matrix( model.pos, model.orientation )
		end
		model.draw( mode )
		if model.respond_to? :attachments
			model.attachments.each{|model|
				draw_model( mode, model ) }
		end
		GL.PopMatrix if mv
	end
	def set_ortho
		GL.MatrixMode(GL::MODELVIEW)
		GL.LoadIdentity
		GL.MatrixMode(GL::PROJECTION)
		GL.PushMatrix
		GL.LoadIdentity()
		GLU.Ortho2D(0.0,@width,0.0,@height)
#		GL.Scale(1,-1,1)
#		GL.Translate(0.0,-@height,0.0)
		GL.MatrixMode(GL::MODELVIEW)
		GL.LoadIdentity
		GL.Disable(GL::DEPTH_TEST)
	end
	def draw_ortho
		set_ortho
		draw_models @ortho_models
		unset_ortho
	end
	def unset_ortho
		GL.Enable(GL::DEPTH_TEST)
		GL.MatrixMode(GL::PROJECTION)
		GL.PopMatrix
		GL.MatrixMode(GL::MODELVIEW)
	end
	def look_at pos, orientation
		up = orientation.vector :up
		forward = orientation.vector :forward
		GL.MatrixMode(GL::MODELVIEW)
		GL.LoadIdentity
		gluLookAt(
			pos.x,pos.y,pos.z,
			pos.x+forward.x,pos.y+forward.y,pos.z+forward.z,
			up.x,up.y,up.z
		)		
	end
##
# TODO - can we use another method here?
#        this seems to be big slow down 
#        orientation.vector does to much
#        math shit in ruby
#
#        Maybe tri ffi-inliner or use ffi call
##
	def load_matrix pos, orientation
		up = orientation.vector :up
		forward = orientation.vector :forward
		right = orientation.vector :right
		GL.MatrixMode(GL::MODELVIEW)
		GL.MultMatrix [
			right.x, right.y, right.z, 0.0,
			up.x, up.y, up.z, 0.0,
			forward.x, forward.y, forward.z, 0.0,
			pos.x, pos.y, pos.z, 1.0
		]
	end
	def set_trans
		GL.DepthMask(GL::FALSE)
		GL.Enable(GL::BLEND)
		GL.BlendFunc(GL::SRC_ALPHA,GL::ONE)
	end
	def unset_trans
		GL.DepthMask(GL::TRUE)
		GL.Disable(GL::BLEND)
	end
	def update_fps
		@frames += 1
		t = Time.now
		seconds = (t - @last_frame).to_i
		return @fps unless seconds >= 1
		@last_frame = t
		@fps = @frames / seconds
		@frames = 0
		@fps
	end
end
