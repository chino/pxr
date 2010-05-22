
	PI2 = sprintf('%.14f',Math::PI * 2).to_f

	# detect if movement would cause collision with other objects
	$world.each do |o|
		# point -> plane
		if o.respond_to? :collision and o.collision == :mesh

				va = o.model.verts # vertex array

o.model.primitives.each do |p|

				normal = Vector.new p[:normal]

			#### local vars

				sep   = ep.dup          # end point
				ssp   = $camera.pos.dup # start point

			#### amount in direction of normal	

				na = normal.dot $camera.velocity

			#### are we perpendicular to the plane ?

				# we can't continue cause t=(blah/na) would devide by 0
				# collision response would have pushed us away from plane by now anyway
				# so we don't really need to worry about doing anything here
				if na == 0.0
					debug "We are moving perpendicular to the plane"
					next
				end

			#### collision points on sphere

				# vector the length of radius in direction of normal 
				r = normal + $camera.radius

				# flip the direction to point towards the plane
				r *= -1 if na < 0

				# add radius to the center to get tip of sphere for contact point
				#ssp += r
				#sep += r

			#### calculate the plane formula

				d = (-normal.x*p[:pos][0]) - (normal.y*p[:pos][1]) - (normal.z*p[:pos][2])

			#### detect if movement places us on other side of plane

				start_distance = normal.dot(ssp) + d
				start_side = (start_distance > 0.0) ? :front : 
											(start_distance < 0.0) ? :back :
											:coincide

				end_distance = normal.dot(sep) + d
				end_side = (end_distance > 0.0) ? :front : 
											(end_distance < 0.0) ? :back :
											:coincide

				if start_side == end_side
					#debug "#{Time.now} No collision"
					next
				end

			#### find collision point on movement vector
#
# apparently I'm able to get right through the middle of two triangle
# by hitting the crack between them
# 
# what I probably need is ability to detect if the entire width of my object moving
# causes a collision... 
#
# not just the exact point of my center position crossing the plane
#

				t = -((normal.dot(ssp) + d) / na)
				cp = ssp + ($camera.velocity*t)

			#### check if point is within polygon

				# add angle between consequtive verts and cp
				radians = 0
				p[:verts].length.times do |i|
					i2 = p[:verts][i+1].nil? ? 0 : i+1 # [i+1] or [0]
					v1 = (Vector.new( va[p[:verts][i ]][:vector] ) - cp ).normalize
					v2 = (Vector.new( va[p[:verts][i2]][:vector] ) - cp ).normalize
begin
					radians += Math.acos(v1.dot(v2))
rescue
	puts "acos arg out of range need to figure out what's wrong here"
	puts p[:verts]
	next
end
				end
				radians = sprintf('%.14f',radians).to_f

				# if add up to 360 degrees then point is within poly
				unless radians == PI2
					debug "#{Time.now} not within polygon - #{radians} != #{PI2}" if radians > 4
					next
				end

				#debug "#{Time.now} polygon collision!"

			#### collision response

				# ammount of movement in direction of normal
				m = normal * na

				# increase by bounce factor
				m += m * $bounce

				# apply to velocity
				$camera.velocity -= m

end # primitives.each

	end

	# apply movement
	$camera.pos += $camera.velocity
}
