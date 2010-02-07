# so things don't break
$window  = Window.new("Model Viewer", $options[:width], $options[:height], $options[:fullscreen])

# generate js array of colors and vertices
$colors = []
$verts = []
$model = Model.new("ship.mxv").model
$model.primitives.each do |primitive|
	primitive[:verts].each do |index|
		$verts << $model.verts[index][:vector].join(',')
		$colors << $model.verts[index][:rgba].join(',')
	end
end

puts "var colors = [" 
puts $colors.join(",\n")
puts "];"

puts "var vertices = ["
puts $verts.join(",\n")
puts "];"
