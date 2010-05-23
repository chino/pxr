require "vector"
require "quat"
module Physics
	module Collision
		module Test
			def self.sphere_sphere a, b
				distance = a.radius + b.radius
				vector = a.pos - b.pos
				vector.length2 <= distance**2
			end
		end
		module Response
			def self.sphere_sphere a, b
				v = a.pos - b.pos
				vn = v.normalize
				bounce = a.bounce + b.bounce
				u1 = vn * vn.dot(a.velocity) # collision component of a's velocity
				u2 = vn * vn.dot(b.velocity) # collision component of b's velocity
				a.velocity -= u1 # remove collision component from velocity
				b.velocity -= u2 # remove collision component from velocity
				vi = u1 * a.mass + u2 * b.mass # both objects would have the same velocity if inelastic
				vea = u1 * (a.mass - b.mass) + u2 * 2 * b.mass # velocity for elastic collision for object a
				veb = u2 * (b.mass - a.mass) + u1 * 2 * a.mass # velocity for elastic collision for object b
				fva = vea * bounce + vi * (1 - bounce) # if bounce = 1, use elastic; if bounce = 0, use inelastic
				fvb = veb * bounce + vi * (1 - bounce) # for values between 0 and 1, pick a point in the middle
				fva /= (a.mass + b.mass) # final velocity of a
				fvb /= (a.mass + b.mass) # final velocity of b
				a.velocity += fva
				b.velocity += fvb
			end
		end
	end
	module BroadPhase
		def self.sphere bodies
			collisions = []
			bodies.each_with_index do |moved,i|
				next unless moved.velocity.length2 > 0 # has movement
				after = moved.dup
				after.pos += after.velocity
				j = i + 1
				while j < bodies.length
					body = bodies[j]
					if Collision::Test::sphere_sphere body, after
						collisions << [body,moved]
						debug "collision"
					end
					j += 1
				end
			end
			collisions
		end
	end
	class Body
		attr_accessor :pos, :orientation, :drag, :velocity, 
				:rotation_velocity, :rotation_drag, :bounce, :mass
		def initialize s={}
			@pos = s[:pos] || Vector.new
			@orientation = s[:orientation] || Quat.new(0, 0, 0, 1).normalize
			@velocity = s[:velocity] || Vector.new
			@drag = s[:drag] || 0.1
			@rotation_velocity = s[:rotation_velocity] || Vector.new
			@rotation_drag = s[:rotation_drag] || 0.5
			@bounce = s[:bounce] || 0.5
			@mass = s[:mass] || 1
		end
		# move body in eyespace
		# vector { x=right-left, y=up-down, z=forward-back }
		def move vector
			# translate vector by our orientation and add it to the position
			@pos += @orientation.vector vector
		end
		def rotate *args
			@orientation.rotate! *args
		end
		def orbit pos, mx,my,mz, rx,ry,rz
			@pos = pos
			rotate rx,ry,rz
			move Vector.new mx,my,mz
		end
		def serialize repr=:short
			# Convert to string suitable for network transmission
			case repr
			when :full
				@pos.serialize(:full) + @orientation.serialize(:full)
			when :short
				@pos.serialize(:full) + @orientation.serialize(:short)
			end
		end
		def unserialize! str, repr=:short
			case repr
			when :full
				pos_s, orient_s = str.unpack "a12a16"
				@pos.unserialize! pos_s, :full
				@orientation.unserialize! orient_s, :full
			when :short
				pos_s, orient_s = str.unpack "a12a8"
				@pos.unserialize! pos_s, :full
				@orientation.unserialize! orient_s, :short
			end
		end
	end
	class SphereBody < Body
		attr_accessor :radius
		def initialize s={}
			super(s)
			@radius = s[:radius] || 50
		end
	end
	class World
		attr_accessor :bodies
		def initialize
			@bodies = []
		end
		def update
			drag
			collisions
			velocities
		end
		def drag
			@bodies.each do |body|
				if body.velocity.length2 > 0
					body.velocity -= body.velocity * body.drag
				end
				if body.rotation_velocity.length2 > 0
					body.rotation_velocity -= body.rotation_velocity * body.rotation_drag
				end
			end
		end
		def collisions
			BroadPhase.sphere( @bodies ).each do |body,moved|
				Collision::Response::sphere_sphere body, moved
			end
		end
		def velocities
			@bodies.each do |body|
				if body.velocity.length2 > 0
					body.pos += body.velocity
				end
				if body.rotation_velocity.length2 > 0
					body.rotate body.rotation_velocity
				end
			end
		end
	end
end
