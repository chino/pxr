require "model"
require "mesh"
class Box < Model
	include Mesh
	def initialize s={}	
		@render_type = GL::QUADS
		@body = s[:body]
		@verts = [
			{:vector => [1,1,1],    :rgba => [255,255,255,0]}, # 0 = top right front
			{:vector => [1,1,-1],   :rgba => [255,255,255,0]}, # 1 = top right back
			{:vector => [1,-1,1],   :rgba => [0,0,255,0]},     # 2 = bot right front
			{:vector => [1,-1,-1],  :rgba => [0,0,255,0]},     # 3 = bot right back
			{:vector => [-1,1,1],   :rgba => [0,255,0,0]},     # 4 = top left front
			{:vector => [-1,1,-1],  :rgba => [0,255,0,0]},     # 5 = top left back
			{:vector => [-1,-1,1],  :rgba => [255,0,0,0]},     # 6 = bot left front
			{:vector => [-1,-1,-1], :rgba => [255,0,0,0]},     # 7 = bot left back
		].each{|v| v[:vector] = (Vector.new(v[:vector]) * @body.half_extents).to_a }
		@primitives = [
			{ :verts => [ 1, 0, 2, 3 ], :texture => s[:texture] }, # right
			{ :verts => [ 4, 5, 7, 6 ], :texture => s[:texture] }, # left
			{ :verts => [ 5, 1, 3, 7 ], :texture => s[:texture] }, # back
			{ :verts => [ 0, 4, 6, 2 ], :texture => s[:texture] }, # front
			{ :verts => [ 5, 4, 0, 3 ], :texture => s[:texture] }, # top
			{ :verts => [ 7, 6, 2, 3 ], :texture => s[:texture] }, # bottom
		]
	end
end
