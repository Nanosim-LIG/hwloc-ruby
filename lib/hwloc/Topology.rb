module Hwloc

  def self.const_missing( sym )
    value = enum_value( sym )

    return super unless value

    value
  end

  class TopologyDiscoverySupport < BoolStruct
    layout :pu, :uchar
  end

  class TopologyCpubindSupport < BoolStruct
    layout :set_thisproc_cpubind,             :uchar,
           :get_thisproc_cpubind,             :uchar,
           :set_proc_cpubind,                 :uchar,
           :get_proc_cpubind,                 :uchar,
           :set_thisthread_cpubind,           :uchar,
           :get_thisthread_cpubind,           :uchar,
           :set_thread_cpubind,               :uchar,
           :get_thread_cpubind,               :uchar,
           :get_thisproc_last_cpu_location,   :uchar,
           :get_proc_last_cpu_location,       :uchar,
           :get_thisthread_last_cpu_location, :uchar
  end

  class TopologyMemSupport < BoolStruct
    topology_mem_support_layout = [
      :set_thisproc_membind,   :uchar,
      :get_thisproc_membind,   :uchar,
      :set_proc_membind,       :uchar,
      :get_proc_membind,       :uchar,
      :set_thisthread_membind, :uchar,
      :get_thisthread_membind, :uchar,
      :set_area_membind,       :uchar,
      :get_area_membind,       :uchar,
      :alloc_membind,          :uchar,
      :firsttouch_membind,     :uchar,
      :bind_membind,           :uchar,
      :interleave_membind,     :uchar
    ]
    topology_mem_support_layout.push(:replicate_membind, :uchar) if API_VERSION < API_VERSION_2_0 
    topology_mem_support_layout += [
      :nexttouch_membind,      :uchar,
      :migrate_membind,        :uchar,
      :get_area_memlocation,   :uchar
    ]
    layout( *topology_mem_support_layout )
  end

  class TopologySupport < Struct
    layout :discovery, TopologyDiscoverySupport.ptr,
           :cpubind,   TopologyCpubindSupport.ptr,
           :membind,   TopologyMemSupport.ptr
  end

  typedef :pointer, :topology
  begin
    typedef :pthread_t, :hwloc_thread_t
  rescue TypeError
    typedef :pointer, :hwloc_thread_t
  end
  typedef :pid_t, :hwloc_pid_t

  attach_function :hwloc_topology_init, [:pointer], :int
  attach_function :hwloc_topology_load, [:topology], :int
  attach_function :hwloc_topology_destroy, [:topology], :void
  attach_function :hwloc_topology_dup, [:pointer, :topology], :int
  attach_function :hwloc_topology_check, [:topology], :void

  if API_VERSION < API_VERSION_2_0 then
    TopologyFlags = bitmask( FFI::find_type(:ulong), :topology_flags, [
      :TOPOLOGY_FLAG_WHOLE_SYSTEM,
      :TOPOLOGY_FLAG_IS_THISSYSTEM,
      :TOPOLOGY_FLAG_IO_DEVICES,
      :TOPOLOGY_FLAG_IO_BRIDGES,
      :TOPOLOGY_FLAG_WHOLE_IO,
      :TOPOLOGY_FLAG_ICACHES
    ] )
  else
    TopologyFlags = bitmask( FFI::find_type(:ulong), :topology_flags, [
      :TOPOLOGY_FLAG_WHOLE_SYSTEM,
      :TOPOLOGY_FLAG_IS_THISSYSTEM,
      :TOPOLOGY_FLAG_THISSYSTEM_ALLOWED_RESOURCES
    ] )
  end

  attach_function :hwloc_topology_set_flags, [:topology, :topology_flags], :int
  attach_function :hwloc_topology_get_flags, [:topology], :topology_flags

  attach_function :hwloc_topology_set_pid, [:topology, :hwloc_pid_t], :int
  if API_VERSION < API_VERSION_2_0 then
    attach_function :hwloc_topology_set_fsroot, [:topology, :string], :int
  end
  attach_function :hwloc_topology_set_synthetic, [:topology, :string], :int
  attach_function :hwloc_topology_set_xml, [:topology, :string], :int
  attach_function :hwloc_topology_set_xmlbuffer, [:topology, :pointer, :size_t], :int
  if API_VERSION < API_VERSION_2_0 then
    attach_function :hwloc_topology_set_custom, [:topology], :int
    attach_function :hwloc_topology_set_distance_matrix, [:topology, :obj_type, :uint, :pointer, :pointer], :int
  else
    attach_function :hwloc_distances_get, [:topology, :pointer, :pointer, :ulong, :ulong], :int
    attach_function :hwloc_distances_get_by_depth, [:topology, :uint, :pointer, :pointer, :ulong, :ulong], :int
    attach_function :hwloc_distances_release, [:topology, Distances.ptr], :void
    attach_function :hwloc_distances_add, [:topology, :uint, :pointer, :pointer, :ulong, :ulong], :int
    attach_function :hwloc_distances_remove, [:topology], :int
    attach_function :hwloc_distances_remove_by_depth, [:topology, :uint], :int
  end
  attach_function :hwloc_topology_is_thissystem, [:topology], :int
  attach_function :hwloc_topology_get_support, [:topology], TopologySupport.ptr
  attach_function :hwloc_topology_get_depth, [:topology], :uint

  GetTypeDepth = enum(:get_type_depth, [
    :TYPE_DEPTH_UNKNOWN, -1,
    :TYPE_DEPTH_MULTIPLE, -2,
    :TYPE_DEPTH_BRIDGE, -3,
    :TYPE_DEPTH_PCI_DEVICE, -4,
    :TYPE_DEPTH_OS_DEVICE, -5
  ] + ( API_VERSION >= API_VERSION_2_0 ? [ :TYPE_DEPTH_MISC, -6 ] : [] ) )

  attach_function :hwloc_get_type_depth, [:topology, :obj_type], :int
  attach_function :hwloc_get_depth_type, [:topology, :uint], :obj_type
  attach_function :hwloc_get_nbobjs_by_depth, [:topology, :uint], :uint

  attach_function :hwloc_get_obj_by_depth, [:topology, :uint, :uint], Obj.ptr

  if API_VERSION < API_VERSION_2_0 then
    attach_function :hwloc_topology_ignore_type, [:topology, :obj_type], :int
    attach_function :hwloc_topology_ignore_type_keep_structure, [:topology, :obj_type], :int
    attach_function :hwloc_topology_ignore_all_keep_structure, [:topology], :int
  else
    TypeFilter = enum(:type_filter, [
      :TYPE_FILTER_KEEP_ALL, 0,
      :TYPE_FILTER_KEEP_NONE, 1,
      :TYPE_FILTER_KEEP_STRUCTURE, 2,
      :TYPE_FILTER_KEEP_IMPORTANT, 3
    ] )
    attach_function :hwloc_topology_set_type_filter, [:topology, :obj_type, :type_filter], :int
    attach_function :hwloc_topology_get_type_filter, [:topology, :obj_type, :pointer], :int
    attach_function :hwloc_topology_set_all_types_filter, [:topology, :type_filter], :int
  end

end

module Hwloc

  class TopologyError < Error
  end

  class Topology
    include Enumerable

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

    def inspect
      return "#<#{self.class}:#{"0x00%x" % (object_id << 1)}>"
    end

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
          raise TopologyError, "Invalid argument"
        end
      else
        raise TopologyError, "Invalid argument"
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

    if API_VERSION < API_VERSION_2_0 then
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
    else
      def set_type_filter(type, filter)
        if type == :all then
          err = Hwloc.hwloc_topology_set_all_types_filter(@ptr, filter)
          raise TopologyError if err == -1
        else
          err = Hwloc.hwloc_topology_set_type_filter(@ptr, type, filter)
          raise TopologyError if err == -1
        end
        return self
      end

      def set_all_types_filter(filter)
        return set_type_filter(:all, filter)
      end

      def get_type_filter(type)
        filter_p = FFI::MemoryPointer::new(TypeFilter.native_type)
        err = Hwloc.hwloc_topology_get_type_filter(@ptr, type, filter_p)
        raise TopologyError if err == -1
        filter = filter_p.read_int
        return TypeFilter[filter]
      end

      def set_cache_types_filter(filter)
        (Hwloc::OBJ_L1CACHE..Hwloc::OBJ_L3ICACHE).each { |cl|
          set_type_filter(cl, filter)
        }
        return self
      end

      def set_icache_types_filter(filter)
        (Hwloc::OBJ_L1ICACHE..Hwloc::OBJ_L3ICACHE).each { |cl|
          set_type_filter(cl, filter)
        }
        return self
      end

      def set_io_types_filter(filter)
        set_type_filter(Hwloc::OBJ_MISC, filter)
        set_type_filter(Hwloc::OBJ_BRIDGE, filter)
        set_type_filter(Hwloc::OBJ_PCI_DEVICE, filter)
        set_type_filter(Hwloc::OBJ_OS_DEVICE, filter)
        return self
      end

      def ignore_type(type)
        return set_type_filter(type, Hwloc::TYPE_FILTER_KEEP_NONE)
      end

      def ignore_type_keep_structure(type)
        set_type_filter(type, Hwloc::TYPE_FILTER_KEEP_STRUCTURE)
      end
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

    def set_pid(pid)
      err = Hwloc.hwloc_topology_set_pid(@ptr, pid)
      raise TopologyError if err == -1
      return self
    end

    if API_VERSION < API_VERSION_2_0 then
      def set_fsroot(fsroot_path)
        err = Hwloc.hwloc_topology_set_fsroot(@ptr, fsroot_path)
        raise TopologyError if err == -1
        return self
      end
    end

    def set_synthetic(description)
      err = Hwloc.hwloc_topology_set_synthetic(@ptr, description)
      raise TopologyError if err == -1
      return self
    end

    def set_xml(xmlpath)
      err = Hwloc.hwloc_topology_set_xml(@ptr, xmlpath)
      raise TopologyError if err == -1
      return self
    end

    def set_xmlbuffer(pointer)
      err = Hwloc.hwloc_topology_set_xmlbuffer(@ptr, pointer, pointer.size)
      raise TopologyError if err == -1
      return self
    end

    if API_VERSION < API_VERSION_2_0 then
      def set_custom
        err = Hwloc.hwloc_topology_set_custom(@ptr)
        raise TopologyError if err == -1
        return self
      end
    end

## Will need some work to define properly...
#    def set_distance_matrix(type, nbobjs, os_index, distances)
#      err = Hwloc.hwloc_topology_set_distance_matrix(@ptr, type, nbobjs, os_index, distances)
#      raise TopologyError if err == -1
#      return self
#    end

    def is_thissystem
      return Hwloc.hwloc_topology_is_thissystem(@ptr) == 1
    end

    alias thissystem? is_thissystem

    def get_support
      p = Hwloc.hwloc_topology_get_support(@ptr)
      p.instance_variable_set(:@topology, self)
      return p
    end

    alias support get_support

    def get_depth
      Hwloc.hwloc_topology_get_depth(@ptr)
    end

    alias depth get_depth

    def get_type_depth(type)
      Hwloc.hwloc_get_type_depth(@ptr, type)
    end

    def get_depth_type(depth)
      type = Hwloc.hwloc_get_depth_type(@ptr, depth)
      raise TopologyError, "Invalid argument" if type == -1
      return type
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
      return each_obj.select{ |e| e.type == type }.count if depth == Hwloc::TYPE_DEPTH_MULTIPLE
      return Hwloc.hwloc_get_nbobjs_by_depth(@ptr, depth)
    end

    def get_obj_by_depth(depth, idx)
      p = Hwloc.hwloc_get_obj_by_depth(@ptr, depth, idx)
      return nil if p.to_ptr.null?
      p.instance_variable_set(:@topology, self)
      return p
    end

    def get_root_obj
      return get_obj_by_depth(0, 0)
    end

    alias root_obj get_root_obj

    def get_obj_by_type(type, idx)
      depth = get_type_depth(type)
      return nil if depth == Hwloc::TYPE_DEPTH_UNKNOWN
      return each_obj.select{ |e| e.type == type }[idx] if depth == Hwloc::TYPE_DEPTH_MULTIPLE
      return get_obj_by_depth(depth, idx)
    end

    def get_next_obj_by_depth(depth, prev)
      return get_obj_by_depth(depth, 0) if prev.nil?
      return nil if prev.depth != depth
      return prev.next_cousin
    end

    def get_next_obj_by_type(type, prev)
      depth = get_type_depth(type)
      return nil if depth == Hwloc::TYPE_DEPTH_UNKNOWN
      if depth == Hwloc::TYPE_DEPTH_MULTIPLE then
        list = each_obj.select{ |e| e.type == type }
        return list[list.find_index { |e| e.to_ptr == e.to_ptr } + 1]
      end
      return get_next_obj_by_depth(depth, prev)
    end

    def each_by_depth(depth)
      if block_given? then
        idx = 0
        while o = get_obj_by_depth(depth, idx) do
          yield o
          idx += 1
        end
        return self
      else
        return Enumerator::new do |yielder|
          idx = 0
          while o = get_obj_by_depth(depth, idx) do
            yielder << o
            idx += 1
          end
        end
      end
    end

    def each_by_type(type, &block)
      depth = get_type_depth(type)
      return each_obj.select{ |e| e.type == type }.each(&block) if depth == Hwloc::TYPE_DEPTH_MULTIPLE
      return each_by_depth(depth, &block)
    end

    ObjType.symbols[0..-1].each { |sym|
      methname = "each_"
      suffix = sym.to_s[4..-1].downcase
      methname += suffix
      define_method(methname) { |&block|
        each_by_type(sym, &block)
      }
      define_method(suffix+"s") {
        send(methname).to_a
      }
    }

    def each_obj(&block)
      if block then
        obj = get_root_obj
        obj.each_obj(&block)
        return self
      else
        to_enum(:each_obj)
      end
    end

    alias traverse each_obj
    alias each each_obj

  end

end
