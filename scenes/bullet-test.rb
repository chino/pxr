#!/usr/bin/env ruby
$: << "#{File.dirname(__FILE__)}/../lib"
$: << "#{File.dirname(__FILE__)}/../conf"
require "rubygems"
require "physics-bullet.rb"
$w = PhysicsBullet::World.new
PhysicsBullet::physics_create_plane(
	 0, # mass=0 is static object
	 0, # plane constant
	 0,1,0, # plane normal
	 0,0,0, # location
	 0,0,0,1 # orientation
)
$radius = 50
8192.times do |i|
	$w.bodies.add Physics::SphereBody.new({
		:pos => Vector.new(0,i*$radius,0),
		:radius => $radius
	})
	puts "created body: #{i}"
end
loop do
	$w.update
	$w.bodies.each_with_index do |b,i|
		puts "#{i} = #{b.pos}"
	end
end
