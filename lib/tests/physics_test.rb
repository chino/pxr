#!/usr/bin/ruby1.9
$: << "../"
require 'physics.rb'

$world = Physics::World.new

100.times do |x|
	y = x * 50.0
	$world.bodies << Physics::SphereBody.new({ 
		:pos => Vector.new( y, y, y ),
		:velocity => Vector.new( x,x,x ),
		:drag => 0
	})
end

loop do
	start = Time.now

	$world.update

	diff = Time.now - start

	puts diff
end
