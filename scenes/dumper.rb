#!/usr/bin/env ruby
#puts "Ruby #{VERSION} (#{RUBY_RELEASE_DATE })"
$: << "#{File.dirname(__FILE__)}/../lib"
$: << "#{File.dirname(__FILE__)}/../conf"
require "rubygems"
require "physics.rb"
require "model.rb"
require "fskn_mx.rb"
require "render"

# data
$model = Model.new({:file => "ship.mxv"}).mesh

# generate js array of colors and vertices
$colors = []
$verts = []
$tcords = []

$start = 0
$last = $model.primitives[0][:texture]
$model.primitives.each_with_index do |primitive,i|
	if $last != primitive[:texture]
		start = $start*3
		count = (i*3) - start
		puts "[#{start},#{count},'#{$last.path.sub 'images', 'textures'}',#{primitive[:transparencies]}],"
		$start = i
		$last = primitive[:texture]
	end
	primitive[:verts].each do |index|
		$verts << $model.verts[index][:vector].join(',')
		$tcords << [
			$model.verts[index][:tu],
			$model.verts[index][:tv],
		].join(',')
		$colors << $model.verts[index][:rgba].map{|c|c/255.0}.join(',')
	end
end

# last one
start = $start*3
count = ($model.primitives.length*3) - start
puts "[#{start},#{count},'#{$last.path.sub 'images', 'textures'}',#{$model.primitives.last[:transparencies]}],"

puts "var colors = [" 
puts $colors.join(",\n")
puts "];"

puts "var vertices = ["
puts $verts.join(",\n")
puts "];"

puts "var textures = ["
puts $model.textures.map{|x|"'#{x}'"}.join(",\n")
puts "];"

puts "var tcords = ["
puts $tcords.join(",\n")
puts "];"
