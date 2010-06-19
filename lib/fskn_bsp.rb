require 'binreader'
class FsknBsp
	class Node
		attr_accessor :normal, :distance, :front, :back, :color
		def initialize tree, normal, distance, front, back, color
			@tree, @normal, @distance, @front, @back, @color = 
				tree, normal, distance, front, back, color
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
	attr_accessor :groups, :collide_node, :collide_point
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
				tree << Node.new( tree, normal, distance, front, back, color )
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
	def render_node node
		Plane.new({
			:pos => node.pos,
			:normal => node.normal,
			:scale => Vector.new(5000,5000,5000),
			:color => node.color
		})
	end
	def point_inside_groups? pos, radius
		@groups.each_with_index do |group,i|
			rv,node = point_inside_group?( pos, i, radius )
			return [rv,node,i] if rv
		end
		return [false,nil,-1]
	end
	def point_inside_group? pos, group, radius
		point_inside_tree?( pos, @groups[group][0], radius )
	end
	@@epsilon = 0.13125 # wide plane to compensate for math errors
	def point_inside_tree? pos, node, radius
		while node
			d = node.normal.dot( pos ) + node.distance
			if    d >  @@epsilon + radius
				unless node.front
					return [true,node]
				else
					node = node.front
				end
			elsif d < -@@epsilon + radius
				unless node.back
					return [false,node]
				else
					node = node.back
				end
			else # coincide
				return [true,node] unless node.front
				rv,n = point_inside_tree?( pos, node.front, radius )
				return [true,n] if rv
				return [false,node] unless node.back
				rv,n = point_inside_tree?( pos, node.back, radius )
				return [false,n] unless rv
				return [true,node]
			end
		end
	end
	def ray_collide body, info={}
		@groups.length.times do |i|
			ray_collide_group( start, dir, info, i )
		end
	end
	def ray_collide_group body, group=0
		root = @groups[group][0]
		start  = body.pos + 0
		stop   = body.pos + body.velocity
		ray_collide_node root, start, stop, body.radius, body.velocity
	end
	def ray_collide_node node, start, stop, radius, velocity

		return false unless node && start && stop

		d1 = node.normal.dot( start ) + node.distance - radius
		d2 = node.normal.dot( stop  ) + node.distance - radius

		d1 = 0.0 if d1 < @@epsilon and d1 > -@@epsilon

		if d2 < @@epsilon and d2 > -@@epsilon 
			if d1 == 0 
				if  node.back and node.front 
					if  ray_collide_node( node.back, start, stop, radius, velocity ) 
						back_collide_node = @collide_node;
						back_collide_point = @collide_point;
						if  ray_collide_node( node.front, start, stop, radius, velocity ) 
							dv = back_collide_point - start
							d1 = dv.length
							dv = @collide_point - start
							d2 = dv.length
							if d1 < d2
								@collide_node = back_collide_node;
								@collide_point = back_collide_point;
							end
						else
							@collide_node = back_collide_node;
							@collide_point = back_collide_point;
						end
						return true;
					else
						return ray_collide_node( node.front, start, stop, radius, velocity );
					end
				elsif  node.back 
					return ray_collide_node( node.back, start, stop, radius, velocity );	
				elsif  node.front 
					return ray_collide_node( node.front, start, stop, radius, velocity );
				else
					return false
				end
				return true
			end
			d2 = 0.0
		end

		if d1 < -radius and d2 < -radius
			if node = node.back 
				return ray_collide_node( node, start, stop, radius, velocity )
			end
			return true
		end
		
		if d1 >= radius and d2 >= radius
			if node = node.front
				return ray_collide_node( node, start, stop, radius, velocity )
			end
			return false
		end

		div = (velocity + node.normal).dot
		distance2plane = (node.normal.dot( start ) + node.distance - radius) / div

		intersection_point = start - (velocity * distance2plane)

		side = d1 < 0
		if side
			near_node = node.back
			far_node = node.front
		else
			near_node = node.front
			far_node = node.back
		end

		return true if ( !near_node and side ) or 
			( near_node and ray_collide_node( 
				near_node, start, intersection_point, radius, velocity ) )

		@collide_node = node;
		@collide_point = intersection_point;

		unless far_node 
			return false if side
			return true
		end

		return ray_collide_node( far_node, intersection_point, stop, radius, velocity )
	end
end
