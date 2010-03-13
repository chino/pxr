# so things don't break
$window  = Window.new("Model Viewer", $options[:width], $options[:height], $options[:fullscreen])

# data
$model = Model.new("ship.mxv").model

# generate js array of colors and vertices
$colors = []
$verts = []
$tcords = []

$start = 0
$last = $model.primitives[0][:texture]
$model.primitives.each_with_index do |primitive,i|
	primitive[:texture].sub! 'images', 'textures'
	if $last != primitive[:texture]
		start = $start*3
		count = (i*3) - start
		puts "[#{start},#{count},'#{$last}'],"
		$start = i
		$last = primitive[:texture]
	end
=begin
	primitive[:verts].each do |index|
		$verts << $model.verts[index][:vector].join(',')
		$tcords << [
			$model.verts[index][:tu],
			$model.verts[index][:tv],
		].join(',')
		$colors << $model.verts[index][:rgba].map{|c|c/255.0}.join(',')
	end
=end
end
start = $start*3
count = ($model.primitives.length*3) - start
puts "[#{start},#{count},#{$last}],"

=begin
#puts "var colors = [" 
puts $colors.join(",\n")
#puts "];"

puts "var vertices = ["
puts $verts.join(",\n")
puts "];"

puts "var textures = ["
puts $model.textures.map{|x|"'#{x}'"}.join(",\n")
puts "];"

puts "var tcords = ["
puts $tcords.join(",\n")
puts "];"
=end
