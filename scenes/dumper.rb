# so things don't break
$window  = Window.new("Model Viewer", $options[:width], $options[:height], $options[:fullscreen])

# generate js array of colors and vertices
$colors = []
$verts = []
$count = 0
$model = Model.new("ship.mxv").model
$model.primitives.each do |primitive|
	primitive[:verts].each do |index|
    $count += 1
		$verts << $model.verts[index][:vector].join(',')
		$colors << $model.verts[index][:rgba].join(',')
	end
end
puts "var colors = [" + $colors.join(',') + "];"
puts "var vertices = [" + $verts.join(',') + "];"
puts "triangleVertexPositionBuffer.numItems = #{$count};"
puts "triangleVertexColorBuffer.numItems = #{$count};"
