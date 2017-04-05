# hwloc-ruby

Simple example using only the compute topology.

```ruby
require 'hwloc'

t = Hwloc::Topology::new
t.flags = Hwloc::Topology::FLAG_ICACHES
t.load

#Get some info on the machine:

o = t.root_obj
puts o.infos


#Print all the object doing a depth first traversal:
t.each { |o|
  puts o
}

#Print all the objects doing a breadth first traversal:
t.depth.times { |d|
  puts t.each_by_depth(d).to_a.join(", ")
}

# find the number of level of caches on the machine and their size:
first_core = t.cores.first
caches = first_core.ancestors.take_while{ |o| o.type == :OBJ_CACHE }
caches.each_with_index { |c,i|
  puts "#{c.type_name}: #{c.attr.size/1024}KiB"
}
```
