require 'binreader'
class FsknBsp
	OUTSIDE = -1
	class Node
		attr_accessor :normal, :distance, :front, :back, :color, :index
		def initialize tree, normal, distance, front, back, color, index
			@tree, @normal, @distance, @front, @back, @color, @index = 
				tree, normal, distance, front, back, color, index
		end
		def pos
			@pos ||= @normal * -@distance
		end 
	end
	@@colors = [
		[255,255,255,255],
		[255,255,0,255],
		[255,0,0,255],
		[0,255,0,255],
		[0,255,255,255],
		[0,0,255,255],
		[255,0,255,255]
	]
	include BinReader
	attr_accessor :groups, :collide_node, :collide_point, :location
	def initialize file
		open( file )
		magic_num, bsp_ver_num = read_int, read_int
		@groups = []
		read_ushort.times do |g| # groups
			tree = []
			read_ushort.times do |n| # nodes
				normal = Vector.new(-read_float,read_float,read_float)
				distance,front,back,color = read_float,read_int,read_int
				color = [read_char,read_char,read_char,read_char]
				color = @@colors[g % @@colors.length]
				tree << Node.new( tree, normal, distance, front, back, color, tree.length )
			end
			@groups << tree
		end
		count = 0
		@groups.each do |tree|
			tree.each do |node|
				count += 1
				node.front = (node.front == 0) ? false : tree[ node.front ]
				node.back  = (node.back  == 0) ? false : tree[ node.back ]
			end
		end
		puts "#{count} nodes in bsp file #{file}" if $options[:debug]
		@location = {} # group which location are in
	end
	def render_planes
		if @planes.nil?
			planes = []
			@groups.each do |group|
				planes << render_group(group)
			end
			@planes = planes.flatten
		else
			@planes
		end
	end
	def render_group group
		planes = []
		group.each_with_index do |node,i|
			planes << render_node(node)
		end
		planes
	end
	def render_node node, pos=nil
		Plane.new({
			:pos => pos||node.pos,
			:normal => node.normal,
			:scale => Vector.new(5000,5000,5000),
			:color => node.color
		})
	end
	def point_inside_groups? pos, radius
		@groups.each_with_index do |group,i|
			#puts "testing group #{i}"
			rv,node = point_inside_group?( pos, i, radius )
			return [rv,node,i] if rv
		end
		return [false,nil,OUTSIDE]
	end
	def point_inside_group? pos, group, radius
		point_inside_tree?( pos, @groups[group][0], radius )
	end
	@@epsilon = 0.13125 # wide plane to compensate for math errors
	def point_inside_tree? pos, node, radius
		while node
			d = node.normal.dot( pos ) + node.distance
			if d >= @@epsilon #+ radius
				if node.front
					node = node.front
				else
					return [true,node]
				end
			elsif d < -@@epsilon #+ radius
				if node.back
					node = node.back
				else
					return [false,node] # collide node
				end
			else
				return [true,node] unless node.front									# is inside if there is no front
				rv,n = point_inside_tree?( pos, node.front, radius )	# 
				return [true,n] if rv																	# is inside if within front
				return [false,node] unless node.back									# is outside if there is no back
				rv,n = point_inside_tree?( pos, node.back, radius )		# 
				return [true,node] if rv															#	is inside if within back
				return [false,n]																			# is outside if not within back
			end
		end
	end
	def ray_collide body, info={}
		@groups.length.times do |i|
			if ray_collide_group( body, i )
				info[:group] = i
				return true
			end
		end
		return false
	end
	def ray_collide_group body, group=0
		@collide_node = nil
		@collide_point = nil
		root = @groups[group][0]
		start  = body.pos + 0
		stop   = body.pos + body.velocity
#		puts "=============== start ============="
		rv = ray_collide_node root, start, stop, body.radius, body.velocity
#		puts "=============== end   ============="
		rv
	end
	def ray_collide_node node, start, stop, radius, velocity

		unless node && start && stop
#			puts "==== returning false because not node && start && stop"
			return false 
		end

		d1 = node.normal.dot( start ) + node.distance# - radius
		d2 = node.normal.dot( stop  ) + node.distance# - radius

#		puts "=== d1 #{d1}"
#		puts "=== d2 #{d2}"

# amazed if this ever goes off
		if d1 < @@epsilon and d1 > -@@epsilon
#puts 0
			d1 = 0.0 
		end
		if d2 < @@epsilon and d2 > -@@epsilon 
#puts 1
			if d1 == 0 
#puts 2
				if  node.back and node.front 
#puts 3
					if  ray_collide_node( node.back, start, stop, radius, velocity ) 
#puts 4
						back_collide_node = @collide_node;
						back_collide_point = @collide_point;
						if  ray_collide_node( node.front, start, stop, radius, velocity ) 
#puts 5
							dv = back_collide_point - start
							d1 = dv.length
							dv = @collide_point - start
							d2 = dv.length
							if d1 < d2
#puts 6
								@collide_node = back_collide_node;
								@collide_point = back_collide_point;
							end
						else
#puts 7
							@collide_node = back_collide_node;
							@collide_point = back_collide_point;
						end
						return true
					else
#puts 8
						return ray_collide_node( node.front, start, stop, radius, velocity );
					end
				elsif  node.back 
#puts 9
					return ray_collide_node( node.back, start, stop, radius, velocity );	
				elsif  node.front 
#puts 10
					return ray_collide_node( node.front, start, stop, radius, velocity );
				else
#puts 11
#					puts "==== returning false because there is no front/back node"
					return false
				end
#puts 12
#				puts "==== returning true but should be impossible to get here"
				return true
			end
#puts 13
			d2 = 0.0
		end

#		puts "=== if #{d1} and #{d2} < #{-radius} then try node.back"

		threshold = @@epsilon + radius

		if d1 < -threshold and d2 < -threshold
			if node = node.back 
				return ray_collide_node( node, start, stop, radius, velocity )
			end
#			puts "=== returning true because d1 < -radius and d2 < -radius and !node.back"
			return true
		end
		
#		puts "=== if #{d1} and #{d2} >= #{radius} then try node.front"

		if d1 >= threshold and d2 >= threshold
			if node = node.front
				return ray_collide_node( node, start, stop, radius, velocity )
			end
			# ray inside level and there is no more front nodes to check
#			puts "=== returning false because d1 >= radius and d2 >= radius and !node.front"
			return false
		end

		cosa = node.normal.dot(velocity)
		distance2plane = (node.normal.dot( start ) + node.distance - radius) / cosa
#		puts "=== dist #{distance2plane}"

		intersection_point = start - (velocity * distance2plane)

		# if our start point was on the back side of plane
		if started_at_back_side = d1 < -@@epsilon #0
			near_node = node.back
			far_node = node.front
		else
			near_node = node.front
			far_node = node.back
		end

		if !near_node and started_at_back_side
#			puts "=== returning true because !near_node and started_at_back_side"
			return true
		end

		if near_node and ray_collide_node( near_node, start, intersection_point, radius, velocity )
#			puts "=== return true because near_node and ray_collide_node"
			return true 
		end

		@collide_node = node;
		@collide_point = intersection_point;

		unless far_node 
			if started_at_back_side
#			puts "=== returning false because !far_node && started_at_back_side"
				return false 
			end
#			puts "=== returning true because !far_node and !started_at_backside"
			return true
		end

#		puts "=== returning ray_collide_node ( far_node, point , ..."
		return ray_collide_node( far_node, intersection_point, stop, radius, velocity )
	end

# start experiment
=begin

	def ray_collide_group2 body, group=0, &block
		root = @groups[group][0]
		start  = body.pos + 0
		stop   = body.pos + body.velocity
		ray_collide_node2 root, start, stop, body.radius, body.velocity, &block
	end

	def ray_collide_node2 node, start, stop, radius, velocity, &block
		
		# distance to plane
		d1 = node.distance - node.normal.dot( start )
		d2 = node.distance - node.normal.dot( stop  )

		# simple cases where ray can be simply thought of as a point
		if d1 < -radius and d2 < -radius
			if node.back
				return ray_collide_node2  node.back, start, stop, radius, velocity, &block
			else
				return true # ray entirely outside form start
			end
		end
		if d1 >= radius and d2 >= radius
			if node.front
				return ray_collide_node2 node.front, start, stop, radius, velocity, &block
			else
				return false # ray entirely inside
			end
		end

		# we hit so send back the node and collision point
		cosa = node.normal.dot velocity
		if cosa == 0
			if d1.abs < radius
				intersection_point = start
				yield intersection_point, node
			end
		else
			side = d1 > 0 ? 1 : d1 < 0 ? -1 : 0
			r = radius * side
			distance2plane = d1 - r / cosa
			intersection_point = start - (velocity * distance2plane)
			yield intersection_point, node
		end

		return true

	end

=end
# end experiment

	def collide bodies
		[bodies].flatten.each do |body|
			
			next unless body.velocity.has_velocity?
		
			stop = body.pos + body.velocity
		
			old_group = @location[body]
			rv,node2,@location[body] = point_inside_groups?( stop, body.radius )

			point_check = false	
	
			if @location[body] == OUTSIDE
				unless old_group.nil? or old_group == OUTSIDE
#					puts "body #{body} would end up leaving level at node #{node2}"
					@location[body] = old_group
					point_check = true
				end

			elsif old_group != @location[body]
#				puts "body #{body} entered level group #{@location[body]}"
				unless old_group.nil? or old_group == OUTSIDE
					point_check = true 
				end
			end
		
			# the most surfaces we can hit at once is 3 walls at a corner
			# thus we run this loop 3 times detection and resolving collisions with nodes
			# from ProcessShips in file ships.c 

			100.times do # added more to stop flying through 
		
				# find out where our movement collided
				collided = ray_collide_group body, @location[body] 

				# no collisions
				unless collided
					if point_check
#						puts "point check says we collided but ray check says we didn't"
						@location[body] = old_group
					end
					break # we are done
				end
				
				# validate we have needed data
				unless @collide_node and @collide_point
#					puts "ray check says we collided but we missing node/point"
					next
				end

				# another check
				if !node2.nil? and node2.index != @collide_node.index
#					puts "point check says we hit node #{node2.index} "+
#						"but ray check says we hit node #{@collide_node.index}"
				end

# start experiment
=begin

				@nodes = []
				if @nodes.include? @collide_node
					puts ":: last loop failed to stop me from colliding against same node"
					exit
					#puts ":: going to test for collision against front node"
					_start = body.pos + 0
					_stop  = body.pos + body.velocity
					if !@last_node.nil? and 
									ray_collide_node @last_node.back, _start, _stop, body.radius, body.velocity
						puts ":: collision found!"
						unless @collide_point and @collide_node
							puts ":: I collided with level but collide point and/or node is/are false"
							next false
						end
					else
						puts ":: no collision found"
					end
				end
				@nodes << @collide_node
				@last_node = @collide_node

=end
# end experiment

				# send body/node/point back to caller so they can perform collision response
				yield body, @collide_node, @collide_point
		
				# if debugging enabled render node we collided with and it's normal
				if $options[:debug]
					d = @collide_node.distance - body.radius
#					puts "collided at point=#{@collide_point} distance=#{d} with:"
#					puts "  node=#{@collide_node.index} normal=#{@collide_node.normal}"
					$render.models << render_node(@collide_node,@collide_point) # planes with normal(0,0,-1) will not render?
					pos = @collide_point.dup; pos.x *= -1 # fix the position for rendering lines
					$render.models << Line.new({:lines => [[
						pos.to_a,
						(pos + (@collide_node.normal * 100)).to_a
					]]})
				end

			end

			# do one last ray check to validate response
			collided = ray_collide_group body, @location[body] 
			if collided
#				puts "failed to contain #{body} in group #{@location[body]} (ray check)" 
				exit
			end

			# do one last point check to validate response
			stop = body.pos + body.velocity
			_in_same_group,_node1 = point_inside_group?( stop, @location[body], body.radius )
			unless _in_same_group
#				puts "failed to contain #{body} in group #{@location[body]} (point check)" 
				exit
			end
		
		end
	end
end
