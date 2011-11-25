require "physics.rb"
require "mesh"
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
	callback :motion_state_callback, [
				:float, :float, :float,					# vector
				:float, :float, :float, :float	# orientation
		], :void

	bind :physics_debug_draw

	bind :physics_debug, [ :pointer ] # body

	bind :physics_init, [:debug_line_callback]

	bind :physics_cleanup

	bind :physics_step, [
			:float, # time passed (since last physics tick)
			:int, # max steps allowed to perform (should equal time_passed / interval)
			:float # interval of each step (bullet by default uses 1/60)
		]

	bind :physics_gravity, [
			:float, :float, :float # vector
		]

	bind :physics_remove_body, [ :pointer ]

	bind :physics_set_friction, [
			:pointer, # body
			:float # friction
		]

	bind :physics_create_sphere, [
			:float, :float, :float, :float, # mass, radius, linear and angular damping
		  :float, :float, :float, # vector
		  :float, :float, :float, :float, # quat
		  :float, :float, :float, # linear velocity (world space)
		  :float, :float, :float, # angular velocity (local space)
		  :motion_state_callback
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

=begin
	bind :physics_body_set_relative_angular_velocity, [
				:pointer, # body
			  :float, :float, :float, # vector
		]

	bind :physics_body_set_velocity, [
				:pointer, # body
			  :float, :float, :float, # vector
		]
=end

	bind :physics_body_apply_central_force, [
				:pointer, # body
			  :float, :float, :float, # vector
		]

	bind :physics_body_apply_relative_central_force, [
				:pointer, # body
			  :float, :float, :float, # vector
		]

	bind :physics_perform_ray_cast_on_bvh, [
				:pointer, # body
				:float, :float, :float, # from
				:float, :float, :float # to
		], :bool

	bind :physics_create_static_bvh_tri_mesh, [
				:int, # number of triangles
				:pointer, # (int) indexes list
				:int, # 3 * 4
				:int, # number of vertices
				:pointer, # (float) vertex list
				:int # 3 * 4
		], :pointer

	require 'line'

	class World
		attr_accessor :bodies, :interval
		def initialize
			@interval = 1.0/60.0
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

				@no_gc << mesh.pointer = PhysicsBullet::physics_create_static_bvh_tri_mesh(
					mesh.primitives.length,
					indexes,
					3*4, # 3 * sizeof(int)
					mesh.verts.length,
					verts,
					3*4 # 3 * sizeof(float)
				)

			elsif body.respond_to? :radius
				@bodies << body
				body.motion_state_callback =
					Proc.new{ |px,py,pz,qx,qy,qz,qw|
						#puts "motion state called with #{px}, #{py}, #{pz}"
						body.pos = Vector.new(px,py,pz)
						body.orientation = Quat.new(qx,qy,qz,qw)
					}
				body.pointer = PhysicsBullet::physics_create_sphere(
					body.mass,
					body.radius, 
					body.linear_damping,
					body.angular_damping,
					*(
						body.pos.to_a + 
						body.orientation.to_a +
						body.linear_velocity.to_a +
						body.angular_velocity.to_a +
						[body.motion_state_callback]
					)
				)
			end

			true
		end
		def remove body
			@bodies.delete body
			PhysicsBullet::physics_remove_body body.pointer
		end
		def update
			step
			#get_updates_from_bullet
		end
		def step time_passed=nil # user supplied if game was paused etc..
			# figure out the time passed
			now = Time.now.to_f
			time_passed = now - (@last_step_time||=now) unless time_passed
			@last_step_time = now
			# number of sub steps to perform at interval to catch up in time
			steps = (time_passed / @interval) + 1 # for rounding
			PhysicsBullet::physics_step time_passed, steps, @interval
			puts "time passed #{time_passed}s "+
						"missed steps #{steps.to_i} "+
						"at interval #{@interval}"
		end
# we now use motion state callbacks for updates
=begin
		def get_updates_from_bullet
			v = FFI::MemoryPointer.new :float, 3
			q = FFI::MemoryPointer.new :float, 4
			@bodies.each do |body|
				PhysicsBullet::physics_body_transform( body.pointer, v, q )
				body.pos = Vector.new( v.get_array_of_float(0,3) )
				body.orientation = Quat.new( q.get_array_of_float(0,4) )
			end
		end
=end
	end

	module CollisionProperties
		attr_accessor :pointer
		def set_friction friction
			PhysicsBullet::physics_set_friction(
				@pointer, friction
			) if @pointer
		end
	end

end
class Physics::Body
	attr_accessor :motion_state_callback
	include PhysicsBullet::CollisionProperties
# velocities right now are only directly applied on
# creation of new bodies in $world.add 
=begin
	def set_velocity v
		@linear_velocity = v
		PhysicsBullet::physics_body_set_velocity(
			@pointer,
			*v.to_a
		)
	end
	def set_angular_velocity v
		@angular_velocity = v
		PhysicsBullet::physics_body_set_relative_angular_velocity(
			@pointer,
			*v.to_a
		)
	end
=end
	def apply_central_force vector
		PhysicsBullet::physics_body_apply_central_force(
			@pointer,
			*vector.to_a
		)
	end
	def apply_relative_torque vector
		PhysicsBullet::physics_body_apply_relative_torque(
			@pointer,
			*vector.to_a
		)
	end
end
module Mesh
	include PhysicsBullet::CollisionProperties
	def ray_cast from, to
		PhysicsBullet::physics_perform_ray_cast_on_bvh(
			@pointer,
			*(from.to_a + to.to_a)
		)
	end
end
