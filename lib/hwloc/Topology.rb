module Hwloc

  typedef :pointer, :topology

  attach_function :hwloc_topology_init, [:pointer], :int
  attach_function :hwloc_topology_load, [:topology], :int
  attach_function :hwloc_topology_destroy, [:topology], :void
  attach_function :hwloc_topology_dup, [:pointer, :topology], :int
  attach_function :hwloc_topology_check, [:topology], :void

  ObjType = enum( :obj_type, [
    :OBJ_SYSTEM,
    :OBJ_MACHINE,
    :OBJ_NUMANODE,
    :OBJ_PACKAGE,
    :OBJ_CACHE,
    :OBJ_CORE,
    :OBJ_PU,
    :OBJ_GROUP,
    :OBJ_MISC,
    :OBJ_BRIDGE,
    :OBJ_PCI_DEVICE,
    :OBJ_OS_DEVICE,
    :OBJ_TYPE_MAX
  ] )

  attach_function :hwloc_topology_ignore_type, [:topology, :obj_type], :int

  def self.const_missing( sym )
    value = enum_value( sym )

    return super unless value

    value
  end

  class Topology
    attr_reader :ptr

    def initialize( *args )
      if args.length == 0 then
        ptr = FFI::MemoryPointer::new( :pointer )
        Hwloc.hwloc_topology_init(ptr)
        @ptr = FFI::AutoPointer::new( ptr.read_pointer, Hwloc.method(:hwloc_topology_destroy) )
      elsif args.length == 1 then
        arg = args[0]
        if arg.kind_of?( Topology ) then
          ptr = FFI::MemoryPointer::new( :pointer )
          Hwloc.hwloc_topology_dup(ptr, arg.ptr)
          @ptr = FFI::AutoPointer::new( ptr.read_pointer, Hwloc.method(:hwloc_topology_destroy) )
        else
          raise ArgumentError, "Invalid argument!"
        end
      else
        raise ArgumentError, "Invalid number of arguments given!"
      end
    end

    def load
      Hwloc.hwloc_topology_load(@ptr)
      return self
    end

    def dup
      return Topology::new( self )
    end

    def check
      Hwloc.hwloc_topology_check(@ptr)
      return self
    end

    def ignore_type(type)
      Hwloc.hwloc_topology_ignore_type(@ptr, type)
    end

  end

end
