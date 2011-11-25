$bindings = {
	"w" => :forward,
	"s" => :back,
	"e" => :up,
	"d" => :down,
	"f" => :left,
	"g" => :right,
	"\r" => :type # enter button
}
$move_accell = 9000.0
$turn_accell = 1000.0
$angular_damping   = 0.899999999999
$linear_damping   = 0.99888
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
