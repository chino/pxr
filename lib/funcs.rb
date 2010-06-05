def dump_modelview
	puts GL.GetFloatv(GL::MODELVIEW_MATRIX).inspect
end
def debug msg
	return unless $options[:debug]
	STDERR.puts msg
end
