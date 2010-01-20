require "rubygems"
require "opengl"

# local libs
ROOT=File.dirname $0
$: << "#{ROOT}/lib/"
require "view"
require "quat"
require "camera"
require "fsknmx"
require "window"
require "mouse"
require "lines"
require "fps"
