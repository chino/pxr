module BinReader
	def open file
		@file = File.open file
	end
	def read count
		@file.read(count).to_s
	end
	def read_str
		str = ""
		while char = @file.read(1)
			break if char == "\0"
			str += char
		end
		str
	end
	def read_char
		read(1).unpack("C")[0]
	end
	def read_int
		read(4).unpack("i")[0]
	end
	def read_ushort
		read(2).unpack("S")[0]
	end
	def read_short
		read(2).unpack("s")[0]
	end
	def read_float
		read(4).unpack("e")[0]
	end
	def read_close
		@file.close
	end
end
