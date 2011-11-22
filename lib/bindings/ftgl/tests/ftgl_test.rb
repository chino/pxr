#!/usr/bin/env ruby

case RUBY_PLATFORM
when /mswin32/
  ENV['PATH'] += (";" + File.expand_path("../ext/ftgl/lib/i386-mswin32"))
  DEFAULT_FONT = "C:/WINNT/Fonts/arial.ttf"
when /darwin/
  DEFAULT_FONT = "./demo/arial.ttf"
else
  DEFAULT_FONT = "/usr/share/fonts/truetype/arial.ttf"
end

$: << "../ext/ftgl"

require 'opengl'
require 'glut'
require 'ftgl'


class FTGLDemo
  attr_reader :display_func, :reshape_func, :keyboard_func
  
  def initialize(font_filename)
    GL.ClearColor(0.0, 0.0, 0.0, 0.0)
    GL.PolygonMode(GL::FRONT_AND_BACK, GL::FILL)
   # GL.ShadeModel(GL::FLAT)

    @width, @height = 1, 1  # set by reshape_func

    @fonts = []
    @fonts[0] = FTGL::OutlineFont.new(font_filename)
    @fonts[1] = FTGL::PolygonFont.new(font_filename)
    @fonts[2] = FTGL::TextureFont.new(font_filename)
    @fonts[3] = FTGL::BitmapFont.new(font_filename)
    @fonts[4] = FTGL::PixmapFont.new(font_filename)
    font_size = 24
    @fonts.each do |font|
      ok = font.SetFaceSize(font_size)
      ok or $stderr.puts "SetFaceSize(#{font_size}) failed for #{font}"
    end
    puts "Bounding box for 'foobar' in PolygonFont: #{
          @fonts[1].BBox("foobar").inspect}"
    
    @display_func = build_display_func
    @reshape_func = build_reshape_func
    @keyboard_func = build_keyboard_func
  end

  private 

  def draw_scene
    GL.Color3f(1.0, 1.0, 1.0)

    lines = %w(abcde fghij jkmno)
    lines.unshift nil

    @fonts.each_with_index do |font, font_idx|
      x = -250.0
      yild = 20.0

      lines[0] = font.inspect
      lines.length.times do |j|
        y = 275.0 - font_idx * 120.0 - j * yild
           
        if font_idx >= 3
          GL.RasterPos(x, y)
          font.Render(lines[j])
        else
          if font_idx == 2
            GL.Enable(GL::TEXTURE_2D)
            GL.Enable(GL::BLEND)
            GL.BlendFunc(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA)
          end
               
          GL.PushMatrix()
            GL.Translate(x, y, 0.0)
            font.Render(lines[j])
          GL.PopMatrix()

          if font_idx == 2
            GL.Disable(GL::TEXTURE_2D)
            GL.Disable(GL::BLEND)
          end
        end
      end
    end
  end

  def do_ortho
    w, h = @width, @height

    # Use the whole window.
    GL.Viewport(0, 0, w, h)

    # We are going to do some 2-D orthographic drawing.
    GL.MatrixMode(GL::PROJECTION)
    GL.LoadIdentity

    size = ((w >= h) ? w : h) / 2.0

    if w <= h
      aspect = h.to_f / w
      GL.Ortho(-size, size, -size*aspect, size*aspect, -100000.0, 100000.0)
    else
      aspect = w.to_f / h
      GL.Ortho(-size*aspect, size*aspect, -size, size, -100000.0, 100000.0)
    end

    # Make the world and window coordinates coincide so that 1.0 in
    # model space equals one pixel in window space.
    GL.Scaled(aspect, aspect, 1.0)

    # Now determine where to draw things.
    GL.MatrixMode(GL::MODELVIEW)
    GL.LoadIdentity
  end

  def build_display_func
    Proc.new {
      GL.Clear(GL::COLOR_BUFFER_BIT)
      draw_scene
      GLUT.SwapBuffers
    }
  end

  def build_reshape_func
    Proc.new {|w, h|
      @width, @height = w, h
      do_ortho
    }
  end

  def build_keyboard_func
    Proc.new {|key, x, y|
      case key
      when 27
        # TODO: how to call font[] destructors ???
        exit(0)
      end
    }
  end
end




GLUT.Init
GLUT.InitDisplayMode(GLUT::DOUBLE | GLUT::RGB)
GLUT.InitWindowSize(700, 700)
GLUT.InitWindowPosition(100, 100)
GLUT.CreateWindow($0)

demo = FTGLDemo.new(DEFAULT_FONT)

GLUT.DisplayFunc(demo.display_func)
GLUT.ReshapeFunc(demo.reshape_func)
GLUT.KeyboardFunc(demo.keyboard_func)
GLUT.MainLoop


