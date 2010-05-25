#!/usr/bin/ruby1.9
$: << "../"
require 'physics.rb'

$world = Physics::World.new

50.times do |x|
	y = x * 200
	$world.add Physics::SphereBody.new({ 
		:pos => Vector.new( y, y, y ),
		:velocity => Vector.new( 1,1,1 ),
		:drag => 0
	})
end

fps = 0
frames = 0
last_frame = 0
loop do
	start = Time.now

	$world.update

	diff = Time.now - start

	frames += 1
	t = Time.now
	seconds = (t - last_frame).to_f
	if seconds >= 1
		last_frame = t
		fps = frames / seconds
		frames = 0
	end

	puts "time = #{diff} fps = #{fps}"
end
