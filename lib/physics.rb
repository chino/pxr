require "vector"
require "quat"
module Physics
	module Collision
		module Test
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
				fa = p + (d * t)
				fb = sp + (d * t)
				# return values back to user
				info[:t] = t
				info[:fa] = fa
				info[:fb] = fb
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
					v = a.velocity - b.velocity
					vlen = v.length2

					# both spheres apparently have same velocity
					# they must be moving parrallel so cannot collide
					# TODO - do we need to now detect if they are already touching? 
					return false if vlen == 0.0

					# reduce test to line segment vs sphere
					# b's radius will increase by a's
					# and 'a' becomes a point
					r = b.radius + a.radius

					# test if line segment passes through sphere
					# line segment representing movement in 'v' from start to finish
					segment_sphere( a.pos, v/vlen, b.pos, r, vlen, info )

			end
		end
		module Response
			def self.sphere_sphere a, b, info

				# since drag is only applied per frame we don't need to update velocity
				#a.velocity = info[:fa] - a.pos
				#b.velocity = info[:fb] - b.pos

				# update sphere positions to the location where they collide
				a.pos = info[:fa]
				b.pos = info[:fb]

				# http://en.wikipedia.org/wiki/Inelastic_collision
				# http://en.wikipedia.org/wiki/Elastic_collision

				v = a.pos - b.pos # vector between spheres
				vn = v.normalize
				u1 = vn * vn.dot(a.velocity) # collision component of velocity
				u2 = vn * vn.dot(b.velocity)
				a.velocity -= u1 # remove collision component
				b.velocity -= u2
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
				a.velocity += fva
				b.velocity += fvb

				# detect if objects are stuck inside one another after movement
				
				afp = a.pos + a.velocity # pos after movement
				bfp = b.pos + b.velocity
				radius = a.radius + b.radius # collision distance
				return unless (afp - bfp).length2 <= radius**2 # penetration

				# separate the objects				

				a.pos += (vn * a.radius) # move them apart by their radius
				b.pos -= (vn * b.radius)

			end
			def self.stop_bodies a, b
				a.velocity = Vector.new
				b.velocity = Vector.new
			end
		end
	end
	module BroadPhase
		def self.sphere bodies
			collisions = []
			bodies.each_with_index do |a,i|
				a_has_velocity = a.velocity.length2 > 0
				# only check each pair once
				j = i + 1; for j in (i+1..bodies.length-1); b = bodies[j]
					# only check if either sphere moving
					next unless a_has_velocity or b.velocity.length2 > 0
					# collect spheres which collide and the time/place it happens
					info = {}; collisions << [a,b,info] if Collision::Test::sphere_sphere a,b,info
				end
			end
			collisions
		end
	end
	class Body
		attr_accessor :pos, :orientation, :drag, :velocity, 
				:rotation_velocity, :rotation_drag, :bounce, :mass, :cell
		def initialize s={}
			@pos = s[:pos] || Vector.new
			@orientation = s[:orientation] || Quat.new(0, 0, 0, 1).normalize
			@velocity = s[:velocity] || Vector.new
			@drag = s[:drag] || 0.1
			@rotation_velocity = s[:rotation_velocity] || Vector.new
			@rotation_drag = s[:rotation_drag] || 0.5
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
			move Vector.new mx,my,mz
		end
		def serialize repr=:short
			# Convert to string suitable for network transmission
			case repr
			when :full
				@pos.serialize(:full) + # 12
				@velocity.serialize(:full) + # 12
				@orientation.serialize(:full) + # 16
				@rotation_velocity.serialize(:full) # 16
				# 56
			when :short
				@pos.serialize(:full) + # 12
				@velocity.serialize(:full) + # 12
				@orientation.serialize(:short) + # 8 
				@rotation_velocity.serialize(:full) # 16
				# 48
			end
		end
		def unserialize! str, repr=:short
			case repr
			when :full
				pos_s, velocity_s, orient_s, rotation_velocity_s = str.unpack "a12a12a16a16"
				@orientation.unserialize! orient_s, :full
			when :short
				pos_s, velocity_s, orient_s, rotation_velocity_s = str.unpack "a12a12a8a16"
				@orientation.unserialize! orient_s, :short
			end
			@pos.unserialize! pos_s, :full
			@velocity.unserialize! velocity_s, :full
			@rotation_velocity.unserialize! rotation_velocity_s, :full
		end
	end
	class SphereBody < Body
		attr_accessor :radius
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
	class Grid
		attr_accessor :size
		def initialize size=1000
			@grid = {}
			@size = size
		end
		def delete body
			return if body.cell.nil?
			@grid[body.cell].delete body
			return if @grid[body.cell].length > 0
			@grid.delete(body.cell)
			body.cell = nil
		end
		def set body
			delete body
			cell = (body.pos / @size).to_a.map{|f|f.to_i}
			setup cell
			@grid[cell] << body
			body.cell = cell
		end
		def setup cell
			return if @grid[cell]
			@grid[cell] = [] 
		end
		def build_row cell, y
			x,y,z = cell[0], cell[1]+y, cell[2]
			cells = []
			c = [x,  y,z  ]; cells << c if @grid[c]
			c = [x,  y,z+1]; cells << c if @grid[c]
			c = [x,  y,z-1]; cells << c if @grid[c]
			c = [x+1,y,z+1]; cells << c if @grid[c]
			c = [x+1,y,z  ]; cells << c if @grid[c]
			c = [x+1,y,z-1]; cells << c if @grid[c]
			c = [x-1,y,z+1]; cells << c if @grid[c]
			c = [x-1,y,z  ]; cells << c if @grid[c]
			c = [x-1,y,z-1]; cells << c if @grid[c]
			cells
		end
		def build_cube cell, &block
			cells  = []
			cells += build_row(cell,  0)
			cells += build_row(cell,  1)
			cells += build_row(cell, -1)
			cells
		end
		def each &block
			@grid.keys.each do |cell|
				bodies = []
				build_cube(cell).each do |cell|
					bodies << @grid[cell]
				end
				yield bodies.flatten
			end
		end
		def draw
			lines = []
			@grid.keys.each do |cell|
				build_cube(cell).each do |cell|
					draw_cell(cell,[255,0,0,0]).each do |line|
						lines << line
					end
				end
			end
			@lines = Line.new({ :lines => lines })
			@lines.draw
		end
		def draw_cell q,c=nil
			x,y,z = q
			x,y,z,s = x*@size, y*@size, z*@size, @size
			lines = []
			if x == 0
				lines << [ [x,y,z], [ x+s, y, z ], c ]
				lines << [ [x,y,z], [ x-s, y, z ], c ]
			else
				sx = x < 0 ? -size : size
				lines << [ [x,y,z], [ x+sx, y, z ], c ]
			end
			if y == 0
				lines << [ [x,y,z], [ x, y+s, z ], c ]
				lines << [ [x,y,z], [ x, y-s, z ], c ]
			else
				sy = y < 0 ? -size : size
				lines << [ [x,y,z], [ x, y+sy, z ], c ]
			end
			if z == 0
				lines << [ [x,y,z], [ x, y, z+s ], c ]
				lines << [ [x,y,z], [ x, y, z-s ], c ]
			else
				sz = z < 0 ? -size : size
				lines << [ [x,y,z], [ x, y, z+sz ], c ]
			end
			return lines
		end
	end
	class World
		attr_accessor :bodies, :grid
		def initialize
			@bodies = []
		end
		def add body
			@bodies << body
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
			pairs = []
			BroadPhase.sphere( @bodies ).each do |pair|
				pairs << pair
			end
			pairs.each do |a,b,info|
				Collision::Response::sphere_sphere a,b,info
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
