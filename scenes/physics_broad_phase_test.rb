#!/usr/bin/env ruby
#puts "Ruby #{VERSION} (#{RUBY_RELEASE_DATE })"
$: << "#{File.dirname(__FILE__)}/../lib"
$: << "#{File.dirname(__FILE__)}/../conf"
require "rubygems"
require "physics.rb"
require "physics-bullet.rb"
require "settings.rb"
require "model.rb"
require "fskn_mx.rb"
require "render"
$render = Render.new($options)

$world = Physics::World.new
$world.broadphase_test = Proc.new{}
#$world.response = Proc.new{}
#$world.interval = nil

$world_bullet = PhysicsBullet::World.new
PhysicsBullet::physics_create_plane(
   0, # mass=0 is static object
   0, # plane constant
   0,1,0, # plane normal
   0,0,0, # location
   0,0,0,1 # orientation
)

if $render
#	$level = Model.new({ :file => "ship.mxv" })
#	$render.models << $level
	$player = Physics::SphereBody.new({
#  	:pos => Vector.new(-550.0,-500.0,4600.0),  #Vector.new(0,0,0),
  	:pos => Vector.new(0,100,0),
	  :drag => 0,
#		:angular_velocity => Vector.new(10,0,0),
  	:rotation_drag => 0,
	  :type => 1,
  	:mask => [1]
	})
#	$player.rotate 0,0,0
	$world.bodies.add $player
end

$objects = 500
$radius = Model.new({ :file => "ball1.mx" }).radius
$distance = $radius * 2
def r; rand * $distance ; end
$pos = Vector.new(0,0,0)

def generate_bodies
	puts "generating bodies"
	$render.models = []
	$world.bodies = []
	$objects.times do |i|
		pos = Vector.new( r-r, i*$radius*2, -2000-r )
#		pos = Vector.new( -r, -r, -4000+r )
#		pos = Vector.new(-(($objects/2)*($radius*2)), 0, -1000)#-6000)
#		pos.x += ($distance * i)
		$world.bodies.add Physics::SphereBody.new({
			:pos => pos,
			:radius => $radius,
#			:velocity => Vector.new(rand*100,0,0),
#			:velocity => Vector.new(1,1,1),
#			:velocity => Vector.new(0.0011,0.0011,0.0011),
			:velocity => Vector.new(r-r,r-r,r-r),
			:drag => 0,
			:angular_velocity => Vector.new(0,0,0),
			:rotation_drag => 0,
			:type => 1,
			:mask => [1]
		})
		if $render
			$render.models << Model.new({
			  :file => "ball1.mx",
  			:body => $world.bodies.last
			})
		end
	end
	puts "finished generating bodies"
	$world_bullet.bodies = $world.bodies
	puts "you have 2 seconds to start recording"
	sleep 2
end

def run world, iterations, name, broadphase=nil
	generate_bodies
	#puts "testing #{world.bodies.length} objects "+
	#		"using #{name} broadphase"
	total = 0
	world.broadphase_test = broadphase unless broadphase.nil?
	collisions = world.broadphase(world.bodies).length unless broadphase.nil?
	collisions = "NA" if broadphase.nil?
	iterations.times do |i|
#		s = Time.now
		#puts "iteration #{i}"
		world.update
#		total += Time.now - s
		if $render
#			$player.rotate 10,0,0
		  $render.draw( $player.pos, $player.orientation ) do
#				world.bodies.each{|body| body.render_radius }
			end
		end
	end
	average = total * 1000 / iterations
	puts "average #{average.to_i}ms "+
#			"out of #{iterations} iteration[s] "+
			"for "+
			"#{world.bodies.length} objects "+
			"using #{name} broadphase "+
			"with #{collisions} collisions"
end

$times = 500

#run $world, $times, "sphere",
#	Proc.new{|*args| Physics::Collision::Test::sphere *args}

#run $world, $times, "aabb",
#	Proc.new{|*args| Physics::Collision::Test::aabb *args}

#run $world, $times, "sphere (ccd)",
#	Proc.new{|*args| Physics::Collision::Test::sphere_sphere *args}

#run $world, $times, "aabb (ccd)",
#	Proc.new{|*args| Physics::Collision::Test::aabb_aabb *args}

run $world_bullet, $times, "bullet"
