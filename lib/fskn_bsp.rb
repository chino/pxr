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
				tree << Node.new( tree, normal, distance, front, back, color )
			end
			@groups << tree
		end
		@groups.each do |tree|
			tree.each do |node|
				node.front = (node.front == 0) ? false : tree[ node.front ]
				node.back  = (node.back  == 0) ? false : tree[ node.back ]
			end
		end
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
			:scale => Vector.new(2500,2500,2500),
			:color => node.color
		})
	end
	def point_inside_trees? pos
		$level_bsp.groups.each do |group|
			return true if point_inside_tree?( pos, group[0] )
		end
		return false
	end
	@@epsilon = 0.03125 # wide plane to compensate for math errors
	def point_inside_tree? pos, node
		while node
			d = node.normal.dot( pos ) + node.distance
			if    d >  @@epsilon; return true  unless node = node.front
			elsif d < -@@epsilon; return false unless node = node.back
			else # coincide
				return true unless node.front
				return true if point_inside_tree?( pos, node.front )
				return false unless node.back
				return false unless point_inside_tree?( pos, node.back )
				return true
			end
		end
	end
end
