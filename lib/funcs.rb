def dump_modelview
	puts GL.GetFloatv(GL::MODELVIEW_MATRIX).inspect
end
