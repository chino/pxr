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
				# http://en.wikipedia.org/wiki/Inelastic_collision
				# http://en.wikipedia.org/wiki/Elastic_collision
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
			bodies.each_with_index do |a,i|
				if a.velocity.length2 > 0
					ae = a.dup
					ae.pos += ae.velocity
				end
				j = i + 1
				for j in (i+1..bodies.length-1) # only check each pair once
					b = bodies[j]

					if a.velocity.length2 > 0
						if Collision::Test::sphere_sphere( ae, b ) # test a's movement
							collisions << [a,b]
							next
						end
					end

					next unless b.velocity.length2 > 0

					be = b.dup
					be.pos += be.velocity
					if Collision::Test::sphere_sphere( a, be ) # test b's movement
						collisions << [a,b]
						next
					end

					next unless a.velocity.length2 > 0

					if Collision::Test::sphere_sphere( ae, be ) # test a's and b's movement
						collisions << [a,b]
					end
				end
			end
			collisions
		end
	end
	class Body
		attr_accessor :pos, :orientation, :drag, :velocity, 
				:rotation_velocity, :rotation_drag, :bounce, :mass, :quadrant
		def initialize s={}
			@pos = s[:pos] || Vector.new
			@orientation = s[:orientation] || Quat.new(0, 0, 0, 1).normalize
			@velocity = s[:velocity] || Vector.new
			@drag = s[:drag] || 0.1
			@rotation_velocity = s[:rotation_velocity] || Vector.new
			@rotation_drag = s[:rotation_drag] || 0.5
			@bounce = s[:bounce] || 0.5
			@mass = s[:mass] || 1
			@quadrant = nil
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
	end
	class Quadrants
		attr_accessor :size
		def initialize size=100
			@quadrants = {}
			@size = size
		end
		def delete body
			return if body.quadrant.nil?
			@quadrants[body.quadrant].delete body
			return if @quadrants[body.quadrant].length > 0
			@quadrants.delete(body.quadrant)
			body.quadrant = nil
		end
		def set body
			delete body
			quad = (body.pos / @size).to_a.map{|f|f.to_i}
			quad[2] = -quad[2]
			setup quad
			@quadrants[quad] << body
			body.quadrant = quad
		end
		def setup quad
			return if @quadrants[quad]
			@quadrants[quad] = [] 
		end
		def neighbors? a, b
			return false if a == b
			return false unless (a[0] - b[0]).abs < 2
			return false unless (a[1] - b[1]).abs < 2
			return false unless (a[2] - b[2]).abs < 2
			return true
		end
		def neighbors quadrant, &block
			@quadrants.each do |q,bds|
				next unless neighbors?( quadrant, q )
				yield q,bds
			end
		end
		def each &block
			@quadrants.each do |quadrant,bodies|
				collection = bodies.dup
				neighbors(quadrant) {|q,bds| collection << bds }
				yield collection.flatten.compact
			end
		end
		def draw
			lines = []
			@quadrants.keys.each do |q|
				draw_quad( q ).each do |line|
					lines << line
				end
				neighbors( q ) do |q,bds|
					draw_quad(q,[255,0,0,0]).each do |line|
						lines << line
					end
				end
			end
			@lines = Line.new lines
			@lines.draw
		end
		def draw_quad q,c=nil
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
		attr_accessor :bodies, :quadrants
		def initialize
			@bodies = []
			@quadrants = Quadrants.new
		end
		def add body
			@bodies << body
			@quadrants.set body
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
			@quadrants.each do |bodies|
				BroadPhase.sphere( bodies ).each do |pair|
					pairs << pair
				end
			end
			pairs.each do |a,b|
				Collision::Response::sphere_sphere a, b
			end
		end
		def velocities
			@bodies.each do |body|
				if body.velocity.length2 > 0
					body.pos += body.velocity
					@quadrants.set body
				end
				if body.rotation_velocity.length2 > 0
					body.rotate body.rotation_velocity
				end
			end
		end
	end
end
