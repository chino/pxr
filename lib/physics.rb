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
	class Quadrants
		attr_accessor :size
		def initialize size=1000
			@quadrants = {}
			@neighbors = {}
			@size = size
		end
		def delete body
			quadrant = nil
			@quadrants.each do |q,bodies|
				unless bodies.delete(body).nil?
					quadrant = q
				end
			end
=begin
			if @neighbors[body.quadrant]
				@neighbors[body.quadrant].each do |neighbor|
					unless @neighbors[neighbor].nil?
						@neighbors[neighbor].delete(body.quadrant)
					end
				end
			end
			@neighbors.delete body.quadrant
=end
			if not quadrant.nil? and @quadrants[quadrant].length > 0
				@quadrants.delete(quadrant)
			end
		end
		def set body
			delete body
			quad = (body.pos / @size).to_a.map{|f|f.to_i}
			quad[2] = -quad[2]
			setup quad
			@quadrants[quad] << body
		end
		def setup quad
			return if @quadrants[quad]
			@quadrants[quad] = [] 
			build_neighbors quad
		end
		def build_neighbors quad
=begin
			@quadrants.each do |name,bodies|
				next unless name[0] - quad[0] < 1
				next unless name[1] - quad[1] < 1
				next unless name[2] - quad[2] < 1
				# only add neighbor relation to one group to limit searching later
				@neighbors[name] = [] unless @neighbors[name]
				@neighbors[name] << quad
				#@neighbors[quad] = [] unless @neighbors[quad]
				#@neighbors[quad] << name
			end
=end
		end
		def each &block
			@quadrants.each do |quadrant,bodies|
				collection = bodies.dup
=begin
				@neighbors[quadrant].each do |quadrant|
					collection << @quadrants[quadrant]
				end unless @neighbors[quadrant].nil?
=end
				yield collection.flatten.compact
			end
		end
		def draw
			lines = []
			@quadrants.keys.each do |x,y,z|
				x,y,z,s = x*@size, y*@size, z*@size, @size
				if x == 0
					lines << [ [x,y,z], [ x+s, y,    z    ] ]
					lines << [ [x,y,z], [ x-s, y,    z    ] ]
				else
					sx = x < 0 ? -size : size
					lines << [ [x,y,z], [ x+sx, y,    z    ] ]
				end
				if y == 0
					lines << [ [x,y,z], [ x,    y+s, z    ] ]
					lines << [ [x,y,z], [ x,    y-s, z    ] ]
				else
					sy = y < 0 ? -size : size
					lines << [ [x,y,z], [ x,    y+sy, z    ] ]
				end
				if z == 0
					lines << [ [x,y,z], [ x,    y,    z+s ] ]
					lines << [ [x,y,z], [ x,    y,    z-s ] ]
				else
					sz = z < 0 ? -size : size
					lines << [ [x,y,z], [ x,    y,    z+sz ] ]
				end
			end
			@lines = Line.new lines
			@lines.draw
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
