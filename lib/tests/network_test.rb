#!/usr/bin/ruby1.9
$: << "../"
require 'network'

$options = {:debug => true}

class Server < Network::Player
	def post_init
		puts "server post_init"
	end
	def receive_data data
		puts "server received data: #{data}"
	end
end

class Client < Network::Player
	def post_init
		puts "client post_init"
	end
	def receive_data data
		puts "client received data: #{data}"
	end
end

server = Network::Server.new( 2300, Server )
client = Network::Client.new( 'localhost', 2300, 2301, Client )

loop do
	client.send_data( 'hi from client' )
	server.pump
	server.send_data( 'hi from server' )
	client.pump
end
