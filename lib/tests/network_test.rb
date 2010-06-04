#!/usr/bin/ruby1.9
$: << "../"
require 'network'

$options = {:debug => false}

server = Network::Server.new( 2300 )
client = Network::Client.new( 'localhost', 2300, 2301 )

loop do
	client.send_data( sprintf("%20s",'hi') )
	client.pump do |ip,msg|
		puts "client recieved: #{ip} #{msg}"
	end
	server.send_data( sprintf("%20s",'hi') )
	server.pump do |ip,msg|
		puts "server recieved: #{ip} #{msg}"
	end
end
