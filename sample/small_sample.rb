[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }
require 'hwloc'
require 'ffi'


# helper function to print memory location (may need pagemap on older version of hwloc)
def print_pointer_location(ptr, t)
  if t.respond_to? :get_area_memlocation
    page_number = (ptr.size.to_f / $page_size).ceil
    base_address = ptr.address - ( ptr.address % $page_size )
    ptrs = page_number.times.collect { |i|
      FFI::Pointer::new(base_address + i*$page_size).slice(0, $page_size)
    }
    ptrs.each { |ptr|
      p t.get_area_memlocation(ptr, :MEMBIND_BYNODESET)
    }
  else
    puts "pagemap #{Process::pid} -n #{ptr.address.to_s(16)}-#{(ptr.address+ptr.size-1).to_s(16)}"
    puts `pagemap #{Process::pid} -n #{ptr.address.to_s(16)}-#{(ptr.address+ptr.size-1).to_s(16)}`
  end
end

t = Hwloc::Topology::new
if Hwloc::API_VERSION < Hwloc::API_VERSION_2_0
  t.flags = Hwloc::Topology::FLAG_ICACHES
else
  t.set_icache_types_filter(:TYPE_FILTER_KEEP_ALL)
end
t.load

if Hwloc::API_VERSION < Hwloc::API_VERSION_2_0
  $page_size = t.machines.first.memory.page_types.first.size
else
  $page_size = 4*1024
end

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
caches = first_core.ancestors.take_while{ |o| o.is_a_cache? }
caches.each_with_index { |c,i|
  puts "#{c.type_name}: #{c.attr.size/1024}KiB"
}

#migrate the execution to different OBJ_PU
t.pus.shuffle.first(3).each { |pu|
  t.set_cpubind(pu.cpuset) {
    puts "Processing on #{t.get_cpubind.to_a}"
    i = 0
    (1<<26).times { i+=1 }
  }
}

#allocate memory on different nodes using hwloc (if you have any)
if t.numanodes.length > 0 then
  ptrs = t.numanodes.collect { |n|
    ptr = t.alloc_membind(10*4*1024, n.cpuset, :MEMBIND_BIND)
    ptr.clear
  }
  sleep 1
  ptrs.each { |ptr|
    p t.get_area_membind(ptr)
    print_pointer_location(ptr, t)
    puts
  }
end

#migrating memory using hwloc (We don't control alignment so last page of each allocation can be migrated twice because it overlaps two memory areas)
if t.numanodes.length > 0 then
  ptrs = t.numanodes.collect { |n|
    ptr = FFI::MemoryPointer::new(10*4*1024)
    t.set_area_membind(ptr, n.cpuset, :MEMBIND_BIND, :MEMBIND_MIGRATE)
    ptr.clear
  }
  sleep 1
  ptrs.each { |ptr|
    p t.get_area_membind(ptr)
    print_pointer_location(ptr, t)
    puts
  }
end

#allocate and migrate memory in an interleaved way
ptr = FFI::MemoryPointer::new(10*4*1024)
t.set_area_membind(ptr, t.machines.first.cpuset, :MEMBIND_INTERLEAVE, :MEMBIND_MIGRATE)
p t.get_area_membind(ptr)
print_pointer_location(ptr, t)

