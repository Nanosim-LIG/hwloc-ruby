module Hwloc

  class Error < RuntimeError
  end

  def self.const_missing( sym )
    value = enum_value( sym )

    return super unless value

    value
  end

  typedef :pointer, :topology

  attach_function :hwloc_get_api_version, [], :uint

  raise Error, "Wrong api version!" if Hwloc.hwloc_get_api_version != 0x00010b00

  attach_function :hwloc_topology_init, [:pointer], :int
  attach_function :hwloc_topology_load, [:topology], :int
  attach_function :hwloc_topology_destroy, [:topology], :void
  attach_function :hwloc_topology_dup, [:pointer, :topology], :int
  attach_function :hwloc_topology_check, [:topology], :void

  attach_function :hwloc_topology_ignore_type, [:topology, :obj_type], :int
  attach_function :hwloc_topology_ignore_type_keep_structure, [:topology, :obj_type], :int
  attach_function :hwloc_topology_ignore_all_keep_structure, [:topology], :int

  TopologyFlags = enum( FFI::find_type(:ulong), :topology_flags, [
    :TOPOLOGY_FLAG_WHOLE_SYSTEM, 1<<0,
    :TOPOLOGY_FLAG_IS_THISSYSTEM, 1<<1,
    :TOPOLOGY_FLAG_IO_DEVICES, 1<<2,
    :TOPOLOGY_FLAG_IO_BRIDGES, 1<<3,
    :TOPOLOGY_FLAG_WHOLE_IO, 1<<4,
    :TOPOLOGY_FLAG_ICACHES, 1<<5
  ] )

  attach_function :hwloc_topology_set_flags, [:topology, :ulong], :int
  attach_function :hwloc_topology_get_flags, [:topology], :ulong

  attach_function :hwloc_topology_get_depth, [:topology], :uint

  GetTypeDepth = enum(:get_type_depth, [
    :TYPE_DEPTH_UNKNOWN, -1,
    :TYPE_DEPTH_MULTIPLE, -2,
    :TYPE_DEPTH_BRIDGE, -3,
    :TYPE_DEPTH_PCI_DEVICE, -4,
    :TYPE_DEPTH_OS_DEVICE, -5
  ] )

  attach_function :hwloc_get_type_depth, [:topology, :obj_type], :int
  attach_function :hwloc_get_depth_type, [:topology, :uint], :obj_type
  attach_function :hwloc_get_nbobjs_by_depth, [:topology, :uint], :uint

  attach_function :hwloc_get_obj_by_depth, [:topology, :uint, :uint], Obj.ptr

end

module Hwloc

  class TopologyError < Error
  end

  class Topology

    def self.const_missing( sym )
      begin
        value = Hwloc.const_get( "TOPOLOGY_#{sym}".to_sym )
        return value
      rescue
      end
      super
    end

    Flags = TopologyFlags

    attr_reader :ptr

    def initialize( *args )
      if args.length == 0 then
        ptr = FFI::MemoryPointer::new( :pointer )
        err = Hwloc.hwloc_topology_init(ptr)
        raise TopologyError if err == -1
        @ptr = FFI::AutoPointer::new( ptr.read_pointer, Hwloc.method(:hwloc_topology_destroy) )
      elsif args.length == 1 then
        arg = args[0]
        if arg.kind_of?( Topology ) then
          ptr = FFI::MemoryPointer::new( :pointer )
          err = Hwloc.hwloc_topology_dup(ptr, arg.ptr)
          raise TopologyError if err == -1
          @ptr = FFI::AutoPointer::new( ptr.read_pointer, Hwloc.method(:hwloc_topology_destroy) )
        else
          raise ArgumentError, "Invalid argument!"
        end
      else
        raise ArgumentError, "Invalid number of arguments given!"
      end
    end

    def load
      err = Hwloc.hwloc_topology_load(@ptr)
      raise TopologyError if err == -1
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
      err = Hwloc.hwloc_topology_ignore_type(@ptr, type)
      raise TopologyError if err == -1
      return self
    end

    def ignore_type_keep_structure(type)
      if type == :all then
        err = Hwloc.hwloc_topology_ignore_all_keep_structure(@ptr)
        raise TopologyError if err == -1
      else
        err = Hwloc.hwloc_topology_ignore_type_keep_structure(@ptr, type)
        raise TopologyError if err == -1
      end
      return self
    end

    def set_flags(flags)
      err = Hwloc.hwloc_topology_set_flags(@ptr, flags)
      raise TopologyError if err == -1
      return self
    end

    alias flags= set_flags

    def get_flags
      Hwloc.hwloc_topology_get_flags(@ptr)
    end

    alias flags get_flags

    def get_depth
      Hwloc.hwloc_topology_get_depth(@ptr)
    end

    alias depth get_depth

    def get_type_depth(type)
      Hwloc.hwloc_get_type_depth(@ptr, type)
    end

    def get_depth_type(depth)
      Hwloc.hwloc_get_depth_type(@ptr, depth)
    end

    def get_type_or_below_depth(type)
      depth = get_type_depth(type)
      return depth if depth != Hwloc::TYPE_DEPTH_UNKNOWN
      depth = get_type_depth(Hwloc::OBJ_PU)
      while depth >= 0 do
        return depth + 1 if Hwloc.compare_types(get_depth_type(depth), type) < 0
        depth -= 1
      end
      raise TopologyError
    end

    def get_type_or_above_depth(type)
      depth = get_type_depth(type)
      return depth if depth != Hwloc::TYPE_DEPTH_UNKNOWN
      depth = 0
      while depth <= get_type_depth(Hwloc::OBJ_PU) do
        return depth - 1 if Hwloc.compare_types(get_depth_type(depth), type) > 0
        depth += 1
      end
      raise TopologyError
    end

    def get_nbobjs_by_depth(depth)
      return Hwloc.hwloc_get_nbobjs_by_depth(@ptr, depth)
    end

    def get_nbobjs_by_type(type)
      depth = get_type_depth(type)
      return 0 if depth == Hwloc::TYPE_DEPTH_UNKNOWN
      return -1 if depth == Hwloc::TYPE_DEPTH_MULTIPLE
      return Hwloc.hwloc_get_nbobjs_by_depth(@ptr, depth)
    end

    def get_root_obj
      return Hwloc.hwloc_get_obj_by_depth(@ptr, 0, 0)
    end

  end

end
