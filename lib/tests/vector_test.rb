#!/usr/bin/env ruby1.9
$: << "../"
require 'vector'
def test name, &block
	t = Time.now
	4000000.times{ block.call }
	t = Time.now - t
	puts "#{name} => #{t}"
end
v = Vector.new 10,10,10
v2 = v.dup
test("addition"){ v+v2 }
test("addition and assignment"){ v=v+v2 }
test("length"){ v.length }
