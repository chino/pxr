#!/usr/bin/env ruby
require 'rubygems'
require "sdl"
require 'optparse'
require 'pp'

# defines
ROOT=File.dirname($0)
DATA="#{ROOT}/data"
LIB="#{ROOT}/lib"
CONF="#{ROOT}/conf"
PROFILE="#{ROOT}/profile.txt"

# load configs
Dir["#{CONF}/*.rb"].sort.each{|file| require file }

# override command line options
OptionParser.new do |opts|
	opts.banner = "Usage: #{$0} [options]"
	opts.on("-h", "--help", "This help"){|v| puts opts; exit 0 }
	opts.on("-s", "--scene SCENE", "Select a scene to load"){|v| $options[:scene] = v }
	opts.on("--profile", "Profile the scene"){|v| $options[:profile] = v }
	opts.on("--port PORT", "Local port to use for networking"){|v| $options[:port] = v }
	opts.on("-f", "--fullscreen", "Run in fullscreen mode"){|v| $options[:fullscreen] = v }
	opts.on("-r", "--res RES", "Resolution <width:height>"){|v| 
		$options[:width],$options[:height] = v.split(":").map{|x|x.to_i} }
	opts.on("-p", "--peer PEER", "Specify the remote peer (host) to connect to"){|v| 
		v =~ /([^:]*):?([0-9]*)?/
		$options[:peer][:address] = $1
		$options[:peer][:port] = $2 unless $2.nil? or $2.empty?
	}
	opts.on("-d", "--debug", "Enable debugging output"){|v|
		$options[:debug] = true
	}
	opts.on("-n", "--name NAME", "Player name"){|v|
		$options[:name] = v
	}
end.parse!

# append load paths
$: << LIB

require 'funcs'

#debug "Command line options:"
#debug pp($options)

# load libs
# make sure your libs require their own dependencies
Dir["#{LIB}/*.rb" ].sort.each{|file| require file }

# profile the scene
# dump profile to file
if $options[:profile]
	require 'ruby-prof'
	RubyProf.start
	at_exit {
		result = RubyProf.stop
		printer = RubyProf::GraphPrinter.new(result)
		file = File.new PROFILE, 'w'
		printer.print(file)
		file.close
		puts "profile saved to #{PROFILE}"
	}
end

# load scene
require "#{$options[:scene]}"
