$bindings = {
	"w" => :forward,
	"s" => :back,
	"e" => :up,
	"d" => :down,
	"f" => :left,
	"g" => :right,
	"\r" => :type # enter button
}
$move_accell = 6000.0
$turn_accell = 3000.0
$turn_drag   = 0.899999999999
$move_drag   = 0.99888
$loaders = {}
$models = "data/models"
$options = {
	:debug => false,
	:profile => false,
	:scene => "./scenes/default.rb",
	:port => 2300,
	:peer => {
		:address => nil,
		:port => 2300
	},
	:fullscreen => false,
	:width => 800.0, #640.0,
	:height => 600.0, #480.0,
	:fov => 70.0,
	:fonts => "data/fonts/",
	:name => "player"
}
