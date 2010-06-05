require 'funcs'
require 'socket'
class Network
	module Socket
		def initialize
			@socket = UDPSocket.new
		end
		def connect ip, port
			@socket.connect ip, port
		end
		def bind port
			@socket.bind '0.0.0.0', port
			debug "binding to port #{port}"
		end
		def ready type=:both
			r = (type == :read) ? [@socket] : nil
			s = (type == :send) ? [@socket] : nil
			r = s = [@socket] if type == :both
			IO.select( r, s, nil, 0 )
		end
		def send ip, port, data
			throw "packet too large" if data.length > 65536
			connect ip, port
			return unless ready :send
			debug "sending data to #{ip} #{port}: #{data}"
			@socket.send data, 0
		rescue
			debug $!
			nil
		end
		def read
			return unless ready :read
			msg = @socket.recvfrom_nonblock(65536)
			return nil if msg.nil?
			data, info = msg
			return nil if data.nil? or data.empty?
			something,port,name,ip = info
			debug "received data from #{ip} #{port}: #{data}"
			[ip, port, data]
		rescue
			debug $!
			nil
		end
	end
	class Player
		attr_accessor :ip, :port, :id, :id_packed
		def initialize ip, port, id
			@ip, @port, @id, @id_packed = ip, port, id, [id].pack('c')
		end
	end
	class Client
		include Socket
		def initialize ip, port, lport, klass
			super()
			@klass = klass
			@ip, @port = ip, port
			@players = {}
			bind lport
			connect ip, port
			debug "connecting to #{ip}:#{port}"
		end
		def pump
			loop do
				ip, port, data = read
				break if ip.nil?
				player_id = data.slice!(0..0).unpack('c')[0]
				player = @players[player_id]
				if player.nil?
					player = @players[player_id] = @klass.new(@ip,@port,player_id)
					debug "new player = #{player.id}"
					player.post_init
				end
				player.receive_data data
			end
		end
		def send_data data
			send @ip, @port, data
		end
	end
	class Server
		include Socket
		def initialize lport, klass
			super()
			@klass = klass
			@players = {}
			@lport = lport
			@id = [0].pack('c') # host is 0
			@@ids = 0 # first player is id 1
			bind lport
		end
		def pump
			loop do
				ip, port, packet = read
				break if ip.nil?
				address = "#{ip}:#{port}"
				c = @players[address]
				if c.nil?
					id = (@@ids+=1)
					debug "player id has rolled over!" if id > 255
					c = @players[address] = @klass.new(ip,port,id)
					debug "new player #{address} id = #{c.id}"
					c.post_init
				end
				proxy c.id_packed, packet
				c.receive_data packet
			end
		end
		def proxy id, data
			return if data.nil?
			msg = id + data
			@players.each do |address,c|
				next if id == c.id
				send( c.ip, c.port, msg )
			end
		end
		def send_data data
			proxy @id, data
		end
	end
end
