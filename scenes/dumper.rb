# so things don't break
$window  = Window.new("Model Viewer", $options[:width], $options[:height], $options[:fullscreen])

# data
$model = Model.new("ship.mxv").model

# generate js array of colors and vertices
$colors = []
$verts = []
$tcords = []
$model.primitives.each do |primitive|
	primitive[:verts].each do |index|
		$verts << $model.verts[index][:vector].join(',')
		$tcords << [
			$model.verts[index][:tu],
			$model.verts[index][:tv],
		].join(',')
		$colors << $model.verts[index][:rgba].join(',')
	end
end

=begin
puts "var colors = [" 
puts $colors.join(",\n")
puts "];"

puts "var vertices = ["
puts $verts.join(",\n")
puts "];"

puts "var textures = ["
puts $model.textures.map{|x|"'#{x}'"}.join(",\n")
puts "];"
=end

puts "var tcords = ["
puts $tcords.join(",\n")
puts "];"

