require 'socket'
class Network
	def initialize ip, port
		@server = UDPSocket.new
		@server.bind("0.0.0.0", 2300)
		@client = UDPSocket.new
		@client.connect ip, port
	end
	def pump
		ready = IO.select([@server], nil, nil, 0.01)
		return unless ready
		#data = @server.recvfrom_nonblock(7*32)[0]
		data = @server.recvfrom(7*32)[0]
		#puts "udp data: " + data
		data
	end
	def send data
		ready = IO.select(nil,[@client], nil, 0.01)
		if ready
			@client.send data, 0 
			#puts "sent data"
		end
	rescue
	end
end
