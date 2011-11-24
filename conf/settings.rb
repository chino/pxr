$bindings = {
	"w" => :forward,
	"s" => :back,
	"e" => :up,
	"d" => :down,
	"f" => :left,
	"g" => :right,
	"\r" => :type # enter button
}
$accell = 2000.0
$move_accell = $accell
$turn_accell = $accell
$drag = 0.899999999
$turn_drag   = $drag
$move_drag   = $drag
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
