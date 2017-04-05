module Hwloc

  attach_function :hwloc_topology_insert_misc_object_by_cpuset, [:topology, :cpuset, :string], Obj.ptr
  attach_function :hwloc_topology_insert_misc_object_by_parent, [:topology, Obj.ptr, :string], Obj.ptr

  RestrictFlags = enum( FFI::find_type(:ulong), :restrict_flags, [
    :RESTRICT_FLAG_ADAPT_DISTANCES, 1<<0,
    :RESTRICT_FLAG_ADAPT_MISC, 1<<1,
    :RESTRICT_FLAG_ADAPT_IO, 1<<2
  ] )

  attach_function :hwloc_topology_restrict, [:topology, :cpuset, :ulong], :int
  attach_function :hwloc_custom_insert_topology, [:topology, Obj.ptr, :topology, Obj.ptr,], :int
  attach_function :hwloc_custom_insert_group_object_by_parent, [:topology, Obj.ptr, :int], Obj.ptr

  class EditionError < TopologyError
  end

  class Topology

    def insert_misc_object_by_cpuset(cpuset, name)
      obj = Hwloc.hwloc_topology_insert_misc_object_by_cpuset(@ptr, cpuset, name)
      raise EditionError if obj.to_ptr.null?
      obj.instance_variable_set(:@topology, self)
      return obj
    end

    def insert_misc_object_by_parent(parent, name)
      obj = Hwloc.hwloc_topology_insert_misc_object_by_parent(@ptr, parent, name)
      raise EditionError if obj.to_ptr.null?
      obj.instance_variable_set(:@topology, self)
      return obj
    end

    def restrict(cpuset, flags)
      err = Hwloc.hwloc_topology_restrict(@ptr, cpuset, flags)
      raise EditionError if err == -1
      return self
    end

    def custom_insert_topology(newparent, oldtopology, oldroot = nil)
      err = Hwloc.hwloc_custom_insert_topology(@ptr, newparent, oldtopology.ptr, oldroot)
      raise EditionError if err == -1
      return self
    end

    def custom_insert_group_object_by_parent(parent, groupdepth)
      obj = Hwloc.hwloc_custom_insert_group_object_by_parent(@ptr, parent, groupdepth)
      raise EditionError if obj.to_ptr.null?
      obj.instance_variable_set(:@topology, self)
      return obj
    end

  end

  class Obj

    def to_topo
      new_topo = Topology::new
      new_topo.set_custom
      new_topo.custom_insert_topology( new_topo.root_obj , @topology, self)
      new_topo.load
      return new_topo
    end

  end

end
