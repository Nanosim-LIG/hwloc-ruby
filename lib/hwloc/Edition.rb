module Hwloc

  attach_function :hwloc_topology_insert_misc_object_by_cpuset, [:topology, :cpuset, :string], Obj.ptr
  attach_function :hwloc_topology_insert_misc_object_by_parent, [:topology, Obj.ptr, :string], Obj.ptr

  RestrictFlags = enum( FFI::find_type(:ulong), :restrict_flags, [
    :RESTRICT_FLAG_ADAPT_DISTANCES, 1<<0,
    :RESTRICT_FLAG_ADAPT_MISC, 1<<1,
    :RESTRICT_FLAG_ADAPT_IO, 1<<2
  ] )

  attach_function :hwloc_topology_restrict, [:topology, :cpuset, :restrict_flags], :int

  class EditionError < TopologyError
  end

  class Topology

    def insert_misc_object_by_cpuset(cpuset, name)
      obj = Hwloc.hwloc_topology_insert_misc_object_by_cpuset(@ptr, cpuset, name)
      raise EditionError if obj.to_ptr.null?
      return obj
    end

    def insert_misc_object_by_parent(parent, name)
      obj = Hwloc.hwloc_topology_insert_misc_object_by_parent(@ptr, parent, name)
      raise EditionError if obj.to_ptr.null?
      return obj
    end

    def restrict(cpuset, flags)
      err = Hwloc.hwloc_topology_restrict(@ptr, cpuset, flags)
      raise EditionError if err == -1
      return self
    end

  end

end
