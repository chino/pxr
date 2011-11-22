#!/usr/bin/env ruby

#
# This script regenerates the SWIG bindings for ruby -> ftgl.
#
# NOTE: There is no need to run this just to build ruby-ftgl,
# as the generated bindings should have already been included
# with the ruby-ftgl sources.
#

case RUBY_PLATFORM
when /mswin32/
  $swigflags = "-I./include/freetype-2.1.10 -I./include/ftgl-2.1.2"
when /darwin/
  $swigflags = ""
else
  $swigflags = ""
end

swig_outfile = "FTGL_wrap.cxx"

File.delete swig_outfile rescue nil

puts "running swig..."
system "swig #$swigflags -includeall -ignoremissing -c++ -ruby FTGL.i"

abort "can't find swig output file #{swig_outfile}" unless test ?f, swig_outfile

puts "patching swig output file..."

dat = File.read swig_outfile

#
# Note: It may be that these patches could have been
# accomplished with SWIG itself.  But I'm a SWIG newbie
# didn't figure it out.

# patch #1
# The FTGL module name is uppercase, but we want
# the .so name to be lowercase for the require
# statement.

unless dat.gsub!(/void\s+Init_FTGL\s*\(void\)/, "void Init_ftgl(void)")
  warn "patch #1 failed"
end

# patch #2
# FaceSize() is an overloaded function in the FTFont base
# class.  One of the derived classes, FTGLTextureFont,
# overrides the two-argument version of FaceSize(), making
# the following code trying to call the zero-argument version,
#   ((FTGLBitmapFont const *)arg1)->FaceSize();
# fail with the error:
#   error C2660: 'FTGLTextureFont::FaceSize' : function does not take 0 arguments
# My c++ is getting rusty, but I presume this means c++ doesn't
# search up the class heirarchy to resolve method overloading.
# So the patch is to cast down to the base class, to call the
# zero-argument version of FaceSize() we're looking for.
#   (static_cast<const FTFont*>((FTGLTextureFont const *)arg1))->FaceSize();

unless dat.gsub!(/\(\s*\(\s*FTGLTextureFont\s+const\s*\*\s*\)\s*arg1\s*\)\s*->\s*FaceSize\s*\(\s*\)\s*;/,
                 "(static_cast<const FTFont*>((FTGLTextureFont const *)arg1))->FaceSize();")
  warn "patch #2 failed"
end


File.open(swig_outfile, "w") {|f| f.print dat }

puts "done."

