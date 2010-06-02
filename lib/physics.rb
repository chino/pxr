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

				v = a.pos - b.pos
				vn = v.normalize
				bounce = a.bounce + b.bounce
				bounce = 1.0 if bounce > 1
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
		def compute_radius verts
			biggest = 0
			center = Vector.new
			verts.each do |vert|
				v = Vector.new(vert[:vector])
				r = (center - v).length2
				biggest = r if r > biggest
			end
			@radius = Math.sqrt(biggest)
		end
		def render_radius
			c = [255,0,0,0]
			x,y,z = @pos.to_a
			z = -z
			r = @radius
			verts = []
			verts << [[x+r,y,  z  ],c]
			verts << [[x-r,y,  z  ],c]
			verts << [[x,  y+r,z  ],c]
			verts << [[x,  y-r,z  ],c]
			verts << [[x,  y,  z+r],c]
			verts << [[x,  y,  z-r],c]
			points = Point.new(verts)
			points.draw
		end
	end
	class Grid
		attr_accessor :size
		def initialize size=100
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
			cell[2] = -cell[2]
			setup cell
			@grid[cell] << body
			body.cell = cell
		end
		def setup cell
			return if @grid[cell]
			@grid[cell] = [] 
		end
		def neighbors? a, b
			return false if a == b
			return false if (a[0] - b[0]).abs > 1
			return false if (a[1] - b[1]).abs > 1
			return false if (a[2] - b[2]).abs > 1
			return true
		end
		def neighbors cell, &block
			@grid.each do |q,bds|
				next unless neighbors?( cell, q )
				yield q,bds
			end
		end
		def each &block
			@grid.each do |cell,bodies|
				collection = bodies.dup
				neighbors(cell) {|q,bds| collection << bds }
				yield collection.flatten.compact
			end
		end
		def draw
			lines = []
			@grid.keys.each do |q|
				draw_cell( q ).each do |line|
					lines << line
				end
				neighbors( q ) do |q,bds|
					draw_cell(q,[255,0,0,0]).each do |line|
						lines << line
					end
				end
			end
			@lines = Line.new lines
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
			@grid = Grid.new
		end
		def add body
			@bodies << body
			@grid.set body
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
# TODO
# what this should really do is find out how many cells an object would move
# then get a list of all bodies within that range of cells to test against
			@grid.each do |bodies|
				BroadPhase.sphere( bodies ).each do |pair|
					pairs << pair
				end
			end
			pairs.each do |a,b,info|
				Collision::Response::sphere_sphere a,b,info
			end
		end
		def velocities
			@bodies.each do |body|
				if body.velocity.length2 > 0
					body.pos += body.velocity
					@grid.set body
				end
				if body.rotation_velocity.length2 > 0
					body.rotate body.rotation_velocity
				end
			end
		end
	end
end
