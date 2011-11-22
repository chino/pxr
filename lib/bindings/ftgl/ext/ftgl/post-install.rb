
# for windows, we've supplied a pre-built libftgl.dll

case RUBY_PLATFORM
when /mswin32/
  install "./lib/i386-mswin32/libftgl.dll", config('bindir'), 0555
end


