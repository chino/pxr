require 'socket'
class Network
	def initialize ip, port=2300, lport=2300
		@server = UDPSocket.new
		@server.bind("0.0.0.0", lport)
		@client = UDPSocket.new
		@client.connect ip, port
	end
	def pump
		ready = IO.select([@server], nil, nil, 0.01)
		return unless ready
		data,info = @server.recvfrom_nonblock(7*32)
		#something,port,domain name,ip = info
		#puts "udp data: " + data unless data.nil? 
		puts "r"
		data
	rescue
	end
	def send data
		ready = IO.select(nil,[@client], nil, 0.01)
		if ready
			@client.send data, 0 
			#puts "w"
		end
	rescue
	end
end
