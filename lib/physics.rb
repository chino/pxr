require "vector"
require "quat"
require "point"
module Physics
	module Collision
		module Test
			PI2 = sprintf('%.14f',Math::PI * 2).to_f
			def self.point_in_poly? p, verts
				# consequtive points between verts should add
				# up to 360 degrees if we are inside polygon
				radians = 0
				verts.length.times do |i|
					i2 = i < verts.length ? i + 1 : 0 # next or first vert
					v1 = ( verts[i ] - p ).normalize
					v2 = ( verts[i2] - p ).normalize
					begin
						radians += Math.acos(v1.dot(v2))
					rescue
						puts "acos arg out of range need to figure out what's wrong here"
						puts verts.inspect
						next
					end
				end
				PI2 == sprintf('%.14f',radians).to_f # equal to 360*
			end
			EPSILON = 0.03125
			def self.sphere_to_plane body, plane, info=nil

				# velocity towards plane
				vtp = plane.normal.dot body.linear_velocity

				# we are moving perpendicular to the plane
				# not much we can do at this point and continuing would cause division by 0
				return false if vtp == 0.0 

				# radius towards plane
				radius = plane.normal + body.radius	# size of radius on normal
				radius *= -1 if vtp < 0			# radius in direction of normal
			
				# start and end point of movement on tip of sphere
				start  = body.pos - radius			# back of sphere before movement
				stop   = body.pos + body.linear_velocity + radius	# front of sphere after movement
			
				# which side of plane was start point ?
				start_distance = plane.normal.dot(start) + plane.distance
				start_side = 	if start_distance > EPSILON
							:front
						elsif start_distance < EPSILON
							:back
						else
							:coincide
						end
			
				# which side of plane was stop point ?
				end_distance = plane.normal.dot(stop) + plane.distance
				end_side =	if end_distance > EPSILON
							:front
						elsif end_distance < EPSILON
							:back
						else
							:coincide
						end
	
				# we didn't collide
				return false if start_side == end_side

				# return collision time and point		
				unless info.nil?
					info[:time] = -((plane.normal.dot(start) + plane.distance) / vtp)
					info[:point] = start + (body.linear_velocity * info[:time])
				end

				# we collided
				return true

			end
# continuous collision detection (sphere vs sphere)
			def self.ray_sphere p, d, sp, sr, info=nil
				m = p - sp
				b = m.dot(d)
				c = m.dot(m) - sr**2
				# test if start point is outside of sphere and pointing away
				return false if c > 0.0 and b > 0.0
				discr = b*b - c
				# if negative than ray missed sphere
				return false if discr < 0.0
				# user doesn't want to know when/where collision happened
				return true if info.nil?
				t = -b - Math.sqrt(discr)
				# if t is negative ray started inside sphere so clamp t
				t = 0.0 if t < 0.0
#				fa = p + (d * t)
#				fb = sp + (d * t)
				# return values back to user
				info[:t] = t
#				info[:fa] = fa
#				info[:fb] = fb
				return true
			end
			def self.segment_sphere p, d, sp, sr, l, info
				# test if the ray passes through the sphere
				return false unless ray_sphere( p, d, sp, sr, info )
				# test that collision point is on the line segment
				info[:t] <= l
			end
			def self.sphere_sphere a, b, info

				# reduce test to only a single moving sphere
				# b becomes a stationary sphere 
				# v represents movement of both spheres
				v = a.linear_velocity - b.linear_velocity
				vlen = v.length2

				# both spheres apparently have same velocity
				# they must be moving parrallel so cannot collide
				if vlen == 0.0
					#puts "falling back to sphere overlap test"
					# lets find out if they are overlapping
					return sphere a, b, info
				end

				# reduce test to line segment vs sphere
				# b's radius will increase by a's
				# and 'a' becomes a point
				r = b.radius + a.radius

				# test if line segment passes through sphere
				# line segment representing movement in 'v' from start to finish
				segment_sphere( a.pos, v/vlen, b.pos, r, vlen, info )

			end
# cotinuous collision detection (aabb vs aabb)
			def self.axis_aabb_min_max s, v, min, max
				# test if we are within volume already
				if s >= min and s <= max
					#puts "we are already inside"
					# return the closest side as the intersection point
					return (s-min).abs < (s-max).abs ? min : max
				end
				# if there is no movement then 
				if v == 0
					#puts "there is no movement and we are not inside to begin with"
					return nil
				end
				# which side can we possibly collide with ?
				d = v > 0 ? min : max
				# do we cross that side after movement ?
				if (s < d) != ((s+v) < d)
					# that is the point we intersect the volume
					return d
				else
					# no intersection
					return nil
				end
			end
			def self.segment_aabb_min_max s, v, c, r, info
				return false if (
					(x = axis_aabb_min_max s.x, v.x, c.x - r, c.x + r).nil? or
					(y = axis_aabb_min_max s.y, v.y, c.y - r, c.y + r).nil? or
					(z = axis_aabb_min_max s.z, v.z, c.z - r, c.z + r).nil?
				)
				info[:point] = Vector.new(x,y,z)
				#puts "intersection at: " + info[:point].to_a.join(',')
				true
			end
			def self.aabb_aabb a, b, info=nil
				# reduce problem to a single moving volume vs a line segment
				v = a.linear_velocity - b.linear_velocity
				vlen = v.length2
				# objects are moving parrallel
				if vlen == 0.0
					puts "falling back to sphere overlap test"
					return sphere a, b, info
				end
				r = b.radius + a.radius
				# test if line segment passes through aabb
				# line segment representing movement in 'v' from start to finish
				# TODO - convert info[:point] back to position for a and b
				segment_aabb_min_max( a.pos, v, b.pos, r, info )
			end		
# non continuous collision detection
# tests for overlapping volumes before movement
			def self.sphere a, b, info=nil
				d = a.radius + b.radius
				(a.pos - b.pos).length2 <= d**2
			end
			def self.aabb a, b, info=nil
				d = a.radius + b.radius
				not (
					(a.pos.x - b.pos.x).abs > d or
					(a.pos.y - b.pos.y).abs > d or
					(a.pos.z - b.pos.z).abs > d
				)
			end
		end
		module Response
			def self.sphere_sphere a, b, info

				# since damping is only applied per frame we don't need to update velocity
				#a.linear_velocity = info[:fa] - a.pos
				#b.linear_velocity = info[:fb] - b.pos

				# update sphere positions to the location where they collide
				a.pos = info[:fa] unless info[:fa].nil?
				b.pos = info[:fb] unless info[:fb].nil?

				# http://en.wikipedia.org/wiki/Inelastic_collision
				# http://en.wikipedia.org/wiki/Elastic_collision

				v = a.pos - b.pos # vector between spheres
				vn = v.normalize
				u1 = vn * vn.dot(a.linear_velocity) # collision component of velocity
				u2 = vn * vn.dot(b.linear_velocity)
				a.linear_velocity -= u1 # remove collision component
				b.linear_velocity -= u2
				vi = u1 * a.mass + u2 * b.mass # vi states if collision is elastic or inelastic
				vea = u1 * (a.mass - b.mass) + u2 * 2 * b.mass # velocity for elastic collision for object a
				veb = u2 * (b.mass - a.mass) + u1 * 2 * a.mass # velocity for elastic collision for object b
				bounce = a.bounce + b.bounce # bounce must be between 0 and 1
				bounce = 1.0 if bounce > 1
				bounce = 0.0 if bounce < 0
				fva = vea * bounce + vi * (1 - bounce) # if bounce = 1, use elastic; if bounce = 0, use inelastic
				fvb = veb * bounce + vi * (1 - bounce) # for values between 0 and 1, pick a point in the middle
				fva /= (a.mass + b.mass) # final velocity of a
				fvb /= (a.mass + b.mass) # final velocity of b
				a.linear_velocity += fva
				b.linear_velocity += fvb

				# detect if objects are stuck inside one another after movement
				
				afp = a.pos + a.linear_velocity # pos after movement
				bfp = b.pos + b.linear_velocity
				radius = a.radius + b.radius # collision distance
				return unless (afp - bfp).length2 <= radius**2 # penetration

				# separate the objects				

#				a.pos += (vn * a.radius) # move them apart by their radius
#				b.pos -= (vn * b.radius)

			end
			def self.stop_bodies a, b
				a.linear_velocity = Vector.new
				b.linear_velocity = Vector.new
			end
		end
	end
	class Body
		attr_accessor :pos, :orientation, :linear_damping, :linear_velocity, :type, :mask
		attr_accessor :angular_velocity, :angular_damping, :bounce, :mass
		def initialize s={}
			@on_collision = s[:on_collision] || Proc.new{true}
			@type = s[:type]
			@mask = s[:mask]
			@pos = s[:pos] || Vector.new
			@orientation = s[:orientation] || Quat.new(0, 0, 0, 1).normalize
			@linear_velocity = s[:linear_velocity] || Vector.new
			@linear_damping = s[:linear_damping] || 0.1
			@angular_velocity = s[:angular_velocity] || Vector.new
			@angular_damping = s[:angular_damping] || 0.5
			@bounce = s[:bounce] || 0.5
			@mass = s[:mass] || 1
			throw "error: mass cannot be zero..." if @mass == 0
			@cell = nil
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
			move Vector.new(mx,my,mz)
		end
		def serialize repr=:short
			# Convert to string suitable for network transmission
			case repr
			when :full
				@pos.serialize(:full) + # 12
				@linear_velocity.serialize(:full) + # 12
				@orientation.serialize(:full) + # 16
				@angular_velocity.serialize(:full) # 16
				# 56
			when :short
				@pos.serialize(:full) + # 12
				@linear_velocity.serialize(:full) + # 12
				@orientation.serialize(:short) + # 8 
				@angular_velocity.serialize(:full) # 16
				# 48
			end
		end
		def unserialize! str, repr=:short
			case repr
			when :full
				pos_s, velocity_s, orient_s, angular_velocity_s = str.unpack "a12a12a16a16"
				@orientation.unserialize! orient_s, :full
			when :short
				pos_s, velocity_s, orient_s, angular_velocity_s = str.unpack "a12a12a8a16"
				@orientation.unserialize! orient_s, :short
			end
			@pos.unserialize! pos_s, :full
			@linear_velocity.unserialize! velocity_s, :full
			@angular_velocity.unserialize! angular_velocity_s, :full
		end
	end
	class SphereBody < Body
		attr_accessor :radius, :on_collision
		def initialize s={}
			super(s)
			@radius = s[:radius] || 50
		end
		def render_radius
			c = [255,0,0,0]
			x,y,z = @pos.to_a
			r = @radius
			verts = []
			verts << [[x+r,y,  z  ],c]
			verts << [[x-r,y,  z  ],c]
			verts << [[x,  y+r,z  ],c]
			verts << [[x,  y-r,z  ],c]
			verts << [[x,  y,  z+r],c]
			verts << [[x,  y,  z-r],c]
			points = Point.new({:points => verts})
			points.draw
		end
	end
	class PlaneBody < Body
		attr_accessor :normal
		def initialize s={}
			super(s)
			@normal = if not s[:normal].nil?
					s[:normal]
				elsif not @orientation.nil?
					@orientation.vector(:forward)
				else
					Vector.new 0,1,0
				end
		end
		def distance
			# TODO - if plane moves then plane formula needs to be recomputed
			@distance ||= @normal.dot(@pos) * -1
		end
		def side pos
			p = normal.dot( pos ) + distance
			(p > 0.0) ? :front : (p < 0.0) ? :back : :coincide
		end
	end
	class World
		attr_accessor :bodies, :grid, :callback, :interval, :broadphase_test, :response
		def initialize
			@gravity = Vector.new(0,0,0)
			@bodies = []
			@last_run = Time.now
			@interval = 1.0/40.0
			@broadphase_test = Proc.new{|*args| Collision::Test::aabb_aabb *args }
			@response = Proc.new{|*args| Collision::Response::sphere_sphere *args }
		end
		def add body
			@bodies << body unless body.respond_to? :mesh
		end
		def remove body
			@bodies.delete body
		end
		def gravity x=nil, y=nil, z=nil
			return @gravity if x.nil?
			@gravity = Vector.new(x,y,z)
		end
		def update
			return unless check_interval
			apply_gravity
			apply_damping
			# test if velocities would cause collision
			# and resolve them 
			collisions
			@callback.call unless @callback.nil?
			# finally apply velocities
			velocities
		end
		def apply_gravity
			return unless @gravity.has_velocity?
			@bodies.each do |body|
				body.linear_velocity += @gravity
			end
		end
		def check_interval
			return true unless @interval
			t = Time.now 
			return false unless (t - @last_run).to_f >= @interval
			@last_run = Time.now
			return true
		end
		def apply_damping
			@bodies.each do |body|
				if body.linear_velocity.has_velocity?
					body.linear_velocity -= body.linear_velocity * body.linear_damping
				end
				if body.angular_velocity.has_velocity?
					body.angular_velocity -= body.angular_velocity * body.angular_damping
				end
			end
		end
		def broadphase bodies
			pairs = []
			bodies.each_with_index do |a,i|
				a_has_velocity = a.linear_velocity.has_velocity?
				# only check each pair once
				j = i + 1; for j in (i+1..bodies.length-1); b = bodies[j]
					#puts "testing body #{i} against #{j}"
					# check collision masks
					next if (not b.mask.include? a.type) and (not a.mask.include? b.type)
					# only check if either sphere moving
					next unless a_has_velocity or b.linear_velocity.has_velocity?
					# collect spheres which collide and the time/place it happens
					info = {}; pairs << [a,b,info] if @broadphase_test.call a,b,info
				end
			end
			pairs
		end
		def collisions
			pairs = []
			broadphase( @bodies ).each do |pair|
				pairs << pair
			end
			#puts "found #{pairs.length} collisions"
			pairs.each do |a,b,info|
				next unless a.on_collision.call( a, b )
				next unless b.on_collision.call( b, a )
				@response.call( a, b, info )
			end
		end
		def velocities
			@bodies.each do |body|
				if body.linear_velocity.has_velocity?
					body.pos += body.linear_velocity
				end
				if body.angular_velocity.has_velocity?
					body.rotate body.angular_velocity
				end
			end
		end
	end
end
