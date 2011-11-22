
require 'mkmf'

c_libs = []
cpp_libs = []

case RUBY_PLATFORM
when /mswin32/
  $CFLAGS = "-DWIN32 -I./include/freetype-2.1.10 -I./include/ftgl-2.1.2"
  $LIBPATH << "./lib/i386-mswin32"
  cpp_libs << "libftgl"
when /darwin/
  abort "set me up for darwin"
else
  $CFLAGS = "-I/usr/include/FTGL -I/usr/include/freetype2 -I/usr/local/include/FTGL -I/usr/local/include/freetype2"
  c_libs << "freetype"
  cpp_libs << "ftgl"
end

c_libs.each{|lib| have_library(lib) }

# hmm, don't think have_library works with c++ libraries
#
# hack: borrow bits of have_library's internals and force
# the result we want:

cpp_libs.each{|lib|
  lib = with_config(lib+'lib', lib)
  puts "ASSUMING we have #{LIBARG%lib} ..."
  $libs = append_library($libs, lib)
}

create_makefile("ftgl")

