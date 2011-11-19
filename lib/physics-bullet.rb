require "physics.rb"
require "rubygems"
require "ffi"
module PhysicsBullet

	extend FFI::Library

	ffi_lib "#{File.dirname(__FILE__)}/../lib/"+
					"physics_bullet.so"

	def self.bind f, args=[], rv=:void
		attach_function f, args, rv
	end

	callback :debug_line_callback, [:pointer], :void

	bind :physics_debug_draw

	bind :physics_init, [:debug_line_callback]

	bind :physics_cleanup

	bind :physics_step, [
			:float # interval in seconds
		]

	bind :physics_gravity, [
			:float, :float, :float # vector
		]

	bind :physics_remove_body, [ :pointer ]

	bind :physics_create_sphere, [
			:float, :float, :float, :float, # mass, radius, linear and angular drag
		  :float, :float, :float, # vector
		  :float, :float, :float, :float # quat
		],
		:pointer # body

	bind :physics_create_plane, [
		  :float, # mass
 			:float, # constant
		  :float, :float, :float, # normal
		  :float, :float, :float, # vector
		  :float, :float, :float, :float # quat
		],
		:pointer # body

	bind :physics_body_transform, [
				:pointer, # body
			  :pointer, # vector
			  :pointer  # quat
		]

	bind :physics_body_apply_torque, [
				:pointer, # body
			  :float, :float, :float, # vector
		]

	bind :physics_body_apply_relative_torque, [
				:pointer, # body
			  :float, :float, :float, # vector
		]

	bind :physics_body_apply_central_force, [
				:pointer, # body
			  :float, :float, :float, # vector
		]

	bind :physics_body_apply_relative_central_force, [
				:pointer, # body
			  :float, :float, :float, # vector
		]

	bind :physics_create_static_bvh_tri_mesh, [
				:int, # number of triangles
				:pointer, # (int) indexes list
				:int, # 3 * 4
				:int, # number of vertices
				:pointer, # (float) vertex list
				:int # 3 * 4
		], :pointer

	class Physics::Body
		attr_accessor :pointer
	end

	class TriangleMesh
		attr_accessor :mesh
		def initialize mesh
			@mesh = mesh
		end
	end

	require 'line'

	class World
		attr_accessor :bodies, :interval
		def initialize
			@no_gc = []
			@bodies = []
			@lines = []
			@debug_line_callback = Proc.new{|floats|
				line=[] # start, end, color
				3.times do |a|
					part = []
					3.times do |b|
						part << floats.get_float32(((a*3)+b)*4)
					end
					line << part
				end
				line[2][3]=1 # transparency
				line[2] = line[2].map{|c|255/c}
				@lines << Line.new({:lines => [ line ]}).make_dl
			}
			# TODO - this should be an option we can flip
			PhysicsBullet::physics_init @debug_line_callback
			gravity 0,0,0
		end
		def draw_lines
			@lines.each do |l|
				l.draw
			end
		end
		def gravity x=nil, y=nil, z=nil
			return @gravity if x.nil?
			PhysicsBullet::physics_gravity x, y, z
			@gravity = Vector.new(x,y,z)
		end
		def add body
			if body.respond_to? :mesh
				mesh = body.mesh

				@no_gc << indexes = FFI::MemoryPointer.new( :int, mesh.primitives.length*3 ).
							put_array_of_int(0,mesh.to_index_array)

				i = -1
				@no_gc << verts = FFI::MemoryPointer.new( :float, mesh.verts.length*3 ).
							put_array_of_float(0,
								mesh.to_indexed_verts_array.
									map{|f| (i+=1) % 3 == 0 ? -f : f }) # flip x axis

				@no_gc << PhysicsBullet::physics_create_static_bvh_tri_mesh(
					mesh.primitives.length,
					indexes,
					3*4, # 3 * sizeof(int)
					mesh.verts.length,
					verts,
					3*4 # 3 * sizeof(float)
				)

			elsif body.respond_to? :radius
				@bodies << body
				body.pointer = PhysicsBullet::physics_create_sphere(
					body.mass,
					body.radius, 
					body.drag,
					body.rotation_drag,
					*(body.pos.to_a + body.orientation.to_a)
				)
				push_velocity_to_bullet body 
				push_rotation_velocity_to_bullet body 
			end
			true
		end
		def remove body
			@bodies.delete body
			PhysicsBullet::physics_remove_body body.pointer
		end
		def update
			n = Time.now.to_f
			@time = n - (@last ||= n - (1.0/60.0))
			@last = n
			push_updates_to_bullet
			PhysicsBullet::physics_step @time
			get_updates_from_bullet
		end
		def push_updates_to_bullet
			@bodies.each do |body|
				push_velocity_to_bullet body
				push_rotation_velocity_to_bullet body
			end
		end
		# body.{pos,orientation,velocity} (world space)
		def push_velocity_to_bullet body
			return unless body.velocity.has_velocity?
			PhysicsBullet::physics_body_apply_central_force(
				body.pointer,
				body.velocity.x, body.velocity.y, body.velocity.z
			)
			body.velocity = Vector.new
		end
		# body.rotation_velocity (local space)
		# 	for easy rotation of pickups, bullets, camera
		def push_rotation_velocity_to_bullet body
			return unless body.rotation_velocity.has_velocity?
			rv = body.rotation_velocity
			PhysicsBullet::physics_body_apply_relative_torque(
				body.pointer,
				rv.x, rv.y, rv.z
			)
			body.rotation_velocity = Vector.new
		end
		# we could use motion states to only update bodies that have changed
		# probably best solution is to somehow pass a proc to bullet to callback
		# http://www.bulletphysics.org/mediawiki-1.5.8/index.php?title=MotionStates
		def get_updates_from_bullet
			v = FFI::MemoryPointer.new :float, 3
			q = FFI::MemoryPointer.new :float, 4
			@bodies.each do |body|
				PhysicsBullet::physics_body_transform( body.pointer, v, q )
				body.pos = Vector.new( v.get_array_of_float(0,3) )
				body.orientation = Quat.new( q.get_array_of_float(0,4) )
			end
		end
	end

end
