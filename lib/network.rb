require 'socket'
class Network
	def initialize ip, port=2300, lport=2300
		@server = UDPSocket.new
		@server.bind("0.0.0.0", lport)
		@client = UDPSocket.new
		@client.connect ip, port
		puts "init - #{ip} #{port}"
	end
	def pump
		ready = IO.select([@server], nil, nil, 0.01)
		return unless ready
		puts "r"
		@server.recvfrom_nonblock(7*32)
	rescue
	end
	def send data
		ready = IO.select(nil,[@client], nil, 0.01)
		@client.send data, 0 if ready
	rescue
	end
end
