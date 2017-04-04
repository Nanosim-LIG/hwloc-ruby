# hwloc-ruby

Simple example using only the compute topology.

```ruby
require 'hwloc'

t = Hwloc::Topology::new
t.load

#Get some info on the machine:

o = t.root_obj
p o.infos


#Print all the object doing a depth first traversal:
t.each { |o|
  puts o
}

#Print all the objects doing a breadth first traversal:
t.depth.times { |d|
  puts t.each_by_depth(d).to_a.join(", ")
}

# find the number of level of caches on the machine and their size:
core = t.get_obj_by_type(:OBJ_CORE, 0)
caches = core.parents.take_while{ |o| o.type == :OBJ_CACHE }
caches.each_with_index { |c,i|
  puts "L#{i+1}_CACHE: #{c.attr[:size]/1024}KiB"
}
```
