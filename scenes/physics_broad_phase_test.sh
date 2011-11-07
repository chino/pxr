#!/bin/bash
#versions=$(rvm list | grep -v rubies | sed 's/=>//g' | awk '{print $1}')
versions="
ruby-1.8.7-p352
ree-head
ruby-1.9.3-head
ruby-head
jruby-head
rbx-head
"
for x in $versions; do echo; echo $x; rvm $x do ruby -v; rvm $x do ./scenes/physics_broad_phase_test.rb; done
echo
