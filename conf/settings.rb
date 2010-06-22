$bindings = {
	"w" => :forward,
	"s" => :back,
	"e" => :up,
	"d" => :down,
	"f" => :left,
	"g" => :right,
	"\r" => :type # enter button
}
$move_accell = 1.0
$move_drag   = 0.1
$turn_accell = 1.0
$turn_drag   = 0.5
$loaders = {}
$models = "data/models"
$options = {
	:debug => false,
	:profile => false,
	:scene => "scenes/default.rb",
	:port => 2300,
	:peer => {
		:address => nil,
		:port => 2300
	},
	:fullscreen => false,
	:width => 640.0,
	:height => 480.0,
	:fov => 70.0,
	:fonts => "data/fonts/"
}
