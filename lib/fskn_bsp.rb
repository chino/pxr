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
	attr_accessor :groups
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
end
