require 'socket'
class Network
	class Socket
		def initialize
			@socket = UDPSocket.new
		end
		def connect ip, port
			@socket.connect ip, port
		end
		def bind port
			@socket.bind '0.0.0.0', port
			puts "binding to port #{port}" if $options[:debug]
		end
		def ready type=:both
			r = (type == :read) ? [@socket] : nil
			s = (type == :send) ? [@socket] : nil
			r = s = [@socket] if type == :both
			IO.select( r, s, nil, 0 )
		end
		def send ip, port, data
			connect ip, port
			return unless ready :send
			puts "sending data" if $options[:debug]
			@socket.send data, 0
		rescue
			puts $! if $options[:debug]
		end
		def read size
			return unless ready :read
			@socket.recvfrom_nonblock size
		rescue
			puts $! if $options[:debug]
		end
		def pump size, &block
			while ready :read
				msg = read(size)
				next if msg.nil?
				data, info = msg
				next if data.nil? or data.empty?
				something,port,name,ip = info
				puts "received data from #{@ip} #{@port}" if $options[:debug]
				yield ip, port, data
			end
		end
	end
	class Client < Socket
		def initialize ip, port, lport
			super()
			bind lport
			connect ip, port
			@ip, @port = ip, port
			puts "connecting to #{ip}:#{port}" if $options[:debug]
		end
		def pump &block
			super(15+20) do |ip,port,data|
				name = data.slice! /.{15}/
				ip = name unless name =~ /host/
				yield ip, data
			end
		end
		def send_data data
			send @ip, @port, data
		end
	end
	class Server < Socket
		def initialize lport
			super()
			bind lport
			@lport = lport
			@connections = {}
		end
		def pump &block
			super(20) do |ip,port,data|
				if @connections[ip].nil?
					@connections[ip] = port
					puts "new connection #{ip}:#{port}" if $options[:debug]
				end
				proxy ip, data
				yield ip, data
			end
		end
		def proxy _ip, data
			data = sprintf "%-15s%s", _ip, data
			@connections.each do |ip,port|
				next if ip == _ip
				send ip, port, data
			end
		end
		def send_data data
			proxy "host", data
		end
	end
end
