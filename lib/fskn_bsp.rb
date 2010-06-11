require 'binreader'
class FsknBsp
	class Node
		attr_accessor :normal, :distance, :front, :back, :color
		def initialize tree, normal, distance, front, back
			@tree, @normal, @distance, @front, @back, @color = 
				tree, normal, distance, front, back, color
		end
	end
	include BinReader
	attr_accessor :groups
	def initialize file
		open( file )
		magic_num, bsp_ver_num = read_int, read_int
		@groups = []
		read_ushort.times do # groups
			tree = []
			read_ushort.times do # nodes
				normal = Vector.new(read_float,read_float,read_float)
				distance,front,back,color = read_float,read_int,read_int,read_int
				tree << Node.new( tree, normal, distance, front, back, color )
			end
			@groups << tree
		end
		@groups.each do |tree|
			tree.each do |node|
				node.front = tree[ node.front ]
				node.back = tree[ node.back ]
			end
		end
	end
end
