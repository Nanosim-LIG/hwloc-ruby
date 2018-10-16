module Hwloc

  class ObjError < Error
  end

  attach_function :hwloc_obj_type_string, [:int], :string

  obj_types = []

  i = 0
  loop do
    str = Hwloc.hwloc_obj_type_string(i)
    break if str == "Unknown"
    obj_types.push :"OBJ_#{str.upcase.gsub("PCIDEV", "PCI_DEVICE").gsub("OSDEV", "OS_DEVICE")}"
    i += 1
  end

  ObjType = enum( :obj_type, obj_types )

  attach_function :hwloc_obj_type_string, [:obj_type], :string
  attach_function :hwloc_compare_types, [:obj_type, :obj_type], :int

  def self.compare_types(type1, type2)
    return Hwloc.hwloc_compare_types(type1, type2)
  end

  ObjCacheType = enum( :obj_cache_type, [
    :OBJ_CACHE_UNIFIED,
    :OBJ_CACHE_DATA,
    :OBJ_CACHE_INSTRUCTION
  ] )

  ObjBrigeType = enum( :obj_bridge_type, [
    :OBJ_BRIDGE_HOST,
    :OBJ_BRIDGE_PCI
  ] )

  ObjOsdevType = enum( :obj_osdev_type, [
    :OBJ_OSDEV_BLOCK,
    :OBJ_OSDEV_GPU,
    :OBJ_OSDEV_NETWORK,
    :OBJ_OSDEV_OPENFABRICS,
    :OBJ_OSDEV_DMA,
    :OBJ_OSDEV_COPROC
  ] )

  class Struct < FFI::Struct

    def method_missing(m, *args, &block)
      begin
        return self[m]
      rescue
        super
      end
    end

    def [](symbol)
      o = super
      o.instance_variable_set(:@topology, @topology) if o.kind_of?(Hwloc::Struct) || o.kind_of?(Hwloc::Union)
      return o
    end

    attr_reader :topology

  end

  class Union < FFI::Union

    def method_missing(m, *args, &block)
      begin
        return self[m]
      rescue
        super
      end
    end

    def [](symbol)
      o = super
      o.instance_variable_set(:@topology, @topology) if o.kind_of?(Hwloc::Struct) || o.kind_of?(Hwloc::Union)
      return o
    end

    attr_reader :topology

  end

  class BoolStruct < FFI::Struct

    def method_missing(m, *args, &block)
      begin
        return self[m] == 1
      rescue
        super
      end
    end

    def each
      if block_given? then
        members.each { |m|
          yield m, (self[m] ==1)
        }
      else
        to_enum(:each)
      end
    end

    attr_reader :topology

  end

  if API_VERSION < API_VERSION_2_0 then
    class Distances < Struct
      layout :relative_depth, :uint,
             :nbobjs,         :uint,
             :latency,        :pointer,
             :latency_max,    :float,
             :latency_base,   :float
    end
  else

    DistancesKind = bitmask(FFI::find_type(:ulong), :distances_kind, [
      :DISTANCES_KIND_FROM_OS,
      :DISTANCES_KIND_FROM_USER,
      :DISTANCES_KIND_MEANS_LATENCY,
      :DISTANCES_KIND_MEANS_BANDWIDTH
    ])

    DistancesAddFlag = bitmask(FFI::find_type(:ulong), :distances_flag, [
      :DISTANCES_ADD_FLAG_GROUP,
      :DISTANCES_ADD_FLAG_GROUP_INACCURATE
    ])

    class Distances < Struct
      layout :nbobjs, :uint,
             :objs,   :pointer,
             :kind,   :distances_kind,
             :values, :pointer

      def objs
        arity = self[:nbobjs]
        if arity == 0 then
          return []
        else
          return self[:objs].read_array_of_pointer(arity).collect { |p|
            c = Obj::new(p)
            c.instance_variable_set(:@topology, @topology)
            c
          }
        end
      end

      def values
        arity = self[:nbobjs]
        arity *= arity
        if arity == 0 then
          return []
        else
          return self[:values].read_array_of_uint64(arity)
        end
      end

      def self.release(ptr)
        Hwloc.hwloc_distances_release(@topology.ptr, ptr)
      end

    end
  end

  class ObjInfo < Struct
    layout :name, :string,
           :value, :string

    def to_s
      return "#{self[:name]}:#{self[:value]}"
    end

  end

  class ObjMemoryPageType < Struct
    layout :size,  :uint64,
           :count, :uint64
    def size
      return self[:size]
    end
  end

  class ObjMemory < Struct
    layout :total_memory, :uint64,
           :local_memory, :uint64,
           :page_types_len, :uint,
           :page_types, :pointer
    def page_types
      page_types_ptr = self[:page_types]
      return page_types_len.times.collect { |i|
        pt = ObjMemoryPageType::new(page_types_ptr+i*ObjMemoryPageType.size)
        pt.instance_variable_set(:@topology, @topology)
        pt
      }
    end
  end

  class NumanodeAttr < Struct
    layout :local_memory, :uint64,
           :page_types_len, :uint,
           :page_types, :pointer
    def page_types
      page_types_ptr = self[:page_types]
      return page_types_len.times.collect { |i|
        pt = ObjMemoryPageType::new(page_types_ptr+i*ObjMemoryPageType.size)
        pt.instance_variable_set(:@topology, @topology)
        pt
      }
    end
  end

  class CacheAttr < Struct
    layout :size,          :uint64,
           :depth,         :uint,
           :linesize,      :uint,
           :associativity, :int,
           :type,          :obj_cache_type
    def size
      return self[:size]
    end
  end

  class GroupAttr < Struct
    group_layout = [ :depth, :uint ]
    if API_VERSION >= API_VERSION_2_0 then
      group_layout += [
        :kind, :uint,
        :subkind, :uint
      ]
    end
    layout( *group_layout )
  end

  class PcidevAttr < Struct
    layout :domain,       :ushort,
           :bus,          :uchar,
           :dev,          :uchar,
           :func,         :uchar,
           :class_id,     :ushort,
           :vendor_id,    :ushort,
           :device_id,    :ushort,
           :subvendor_id, :ushort,
           :subdevice_id, :ushort,
           :revision,     :uchar,
           :linkspeed,    :float
  end

  class AnonBridgeAttrUpstream < Union
    layout :pci, PcidevAttr
  end

  class AnonBridgeAttrDownstreamStruct < Struct
    layout :domain,          :ushort,
           :secondary_bus,   :uchar,
           :subordinate_bus, :uchar
  end

  class AnonBridgeAttrDownstream < Union
    layout :pci, AnonBridgeAttrDownstreamStruct
  end

  class BridgeAttr < Struct
    layout :upstream,        AnonBridgeAttrUpstream,
           :upstream_type,   :obj_bridge_type,
           :downstream,      AnonBridgeAttrDownstream,
           :downstream_type, :obj_bridge_type,
           :depth,           :uint
  end

  class OsdevAttr < Struct
    layout :type, :obj_osdev_type
  end

  class ObjAttr < Union
    if API_VERSION < API_VERSION_2_0 then
      layout :cache,  CacheAttr,
             :group,  GroupAttr,
             :pcidev, PcidevAttr,
             :bridge, BridgeAttr,
             :osdev,  OsdevAttr
    else
      layout :numanode, NumanodeAttr,
             :cache,  CacheAttr,
             :group,  GroupAttr,
             :pcidev, PcidevAttr,
             :bridge, BridgeAttr,
             :osdev,  OsdevAttr
    end
  end

  class Obj < Struct
  end

  attach_function :hwloc_obj_type_snprintf, [:pointer, :size_t, Obj.ptr, :int], :int
  attach_function :hwloc_obj_attr_snprintf, [:pointer, :size_t, Obj.ptr, :string, :int], :int

  class Obj
    if API_VERSION < API_VERSION_2_0 then
      layout_array = [
        :type,             :obj_type,
        :os_index,         :uint,
        :name,             :string,
        :memory,           ObjMemory,
        :attr,             ObjAttr.ptr,
        :depth,            :uint,
        :logical_index,    :uint,
        :os_level,         :int,
        :next_cousin,      Obj.ptr,
        :prev_cousin,      Obj.ptr,
        :parent,           Obj.ptr,
        :sibling_rank,     :uint,
        :next_sibling,     Obj.ptr,
        :prev_sibling,     Obj.ptr,
        :arity,            :uint,
        :children,         :pointer,
        :first_child,      Obj.ptr,
        :last_child,       Obj.ptr,
        :user_data,        :pointer,
        :cpuset,           :cpuset,
        :complete_cpuset,  :cpuset,
        :online_cpuset,    :cpuset,
        :allowed_cpuset,   :cpuset,
        :nodeset,          :nodeset,
        :complete_nodeset, :nodeset,
        :allowed_nodeset,  :nodeset,
        :distances,        :pointer,
        :distances_count,  :uint,
        :infos,            :pointer,
        :infos_count,      :uint,
        :symmetric_subtree,:int
      ]
    else
      layout_array = [
        :type,              :obj_type,
        :subtype,           :string,
        :os_index,          :uint,
        :name,              :string,
        :total_memory,      :uint64,
        :attr,              ObjAttr.ptr,
        :depth,             :uint,
        :logical_index,     :uint,
        :next_cousin,       Obj.ptr,
        :prev_cousin,       Obj.ptr,
        :parent,            Obj.ptr,
        :sibling_rank,      :uint,
        :next_sibling,      Obj.ptr,
        :prev_sibling,      Obj.ptr,
        :arity,             :uint,
        :children,          :pointer,
        :first_child,       Obj.ptr,
        :last_child,        Obj.ptr,
        :symmetric_subtree, :int,
        :memory_arity,      :uint,
        :memory_first_child,Obj.ptr,
        :io_arity,          :uint,
        :io_first_child,    Obj.ptr,
        :misc_arity,        :uint,
        :misc_first_child,  Obj.ptr,
        :cpuset,            :cpuset,
        :complete_cpuset,   :cpuset,
        :nodeset,           :nodeset,
        :complete_nodeset,  :nodeset,
        :infos,             :pointer,
        :infos_count,       :uint,
        :user_data,         :pointer,
        :gp_index,          :uint64
      ]
    end

    layout *layout_array

    def ==(other)
      return other.kind_of?(Obj) && to_ptr == other.to_ptr
    end

    def type_snprintf(verbose=0)
      sz = Hwloc.hwloc_obj_type_snprintf(nil, 0, self, verbose) + 1
      str_ptr = FFI::MemoryPointer::new(:char, sz)
      Hwloc.hwloc_obj_type_snprintf(str_ptr, sz, self, verbose)
      return str_ptr.read_string
    end

    def type_string
      return Hwloc.hwloc_obj_type_string(type)
    end
    alias type_name type_string

    def attr_snprintf(verbose=0, separator=",")
      sz = Hwloc.hwloc_obj_attr_snprintf(nil, 0, self, separator, verbose) + 1
      str_ptr = FFI::MemoryPointer::new(:char, sz)
      Hwloc.hwloc_obj_attr_snprintf(str_ptr, sz, self, separator, verbose)
      return str_ptr.read_string
    end

    def to_s(verbose=0)
      attr_str = attr_snprintf(verbose)
      str = "#{type_snprintf(verbose)} L##{logical_index}"
      str += " (#{attr_str})" if attr_str != ""
      return str
    end

    def inspect
      return to_s(1)
    end

    layout_array.each_slice(2) { |f|
      case f[1]
      when :cpuset
        define_method(f[0]) {
          p = self[f[0]]
          return nil if p.null?
          return Cpuset::new(p)
        }
      when :nodeset
        define_method(f[0]) {
          p = self[f[0]]
          return nil if p.null?
          return Nodeset::new(p)
        }
      when Obj.ptr
        define_method(f[0]) {
          p = self[f[0]]
          return nil if p.to_ptr.null?
          return p
        }
      end
    }

    alias previous_sibling prev_sibling
    alias previous_cousin prev_cousin

    def children
      arity = self[:arity]
      if arity == 0 then
        return []
      else
        return self[:children].read_array_of_pointer(arity).collect { |p|
          c = Obj::new(p)
          c.instance_variable_set(:@topology, @topology)
          c
        }
      end
    end

    def each_child(*args, &block)
      return children.each(*args, &block)
    end

    if API_VERSION < API_VERSION_2_0 then
      def each_obj(&block)
        if block then
          block.call self
          children.each { |c|
            c.each_obj(&block)
          }
          return self
        else
          to_enum(:each_obj)
        end
      end

      def each_descendant(&block)
        if block then
          children.each { |c|
            c.each_obj(&block)
          }
        else
          to_enum(:each_descendant)
        end
      end

    else

      def memory_children
        return [] if memory_arity == 0
        c = []
        c.push( memory_first_child )
        (memory_arity-1).times {
          c.push( c[-1].next_sibling )
        }
        return c
      end

      def each_memory_child(*args, &block)
        return memory_children.each(*args, &block)
      end

      def io_children
        return [] if io_arity == 0
        c = []
        c.push( io_first_child )
        (io_arity-1).times {
          c.push( c[-1].next_sibling )
        }
        return c
      end

      def each_io_child(*args, &block)
        return io_children.each(*args, &block)
      end

      def misc_children
        return [] if misc_arity == 0
        c = []
        c.push( misc_first_child )
        (misc_arity-1).times {
          c.push( c[-1].next_sibling )
        }
        return c
      end

      def each_misc_child(*args, &block)
        return misc_children.each(*args, &block)
      end

      def each_obj(&block)
        if block then
          block.call self
          (children+io_children+misc_children).each { |c|
            c.each_obj(&block)
          }
          return self
        else
          to_enum(:each_obj)
        end
      end

      def each_descendant(&block)
        if block then
          (children+io_children+misc_children).each { |c|
            c.each_obj(&block)
          }
        else
          to_enum(:each_descendant)
        end
      end

    end

    def each_parent(&block)
      if block then
        if parent then
          block.call parent
          parent.each_parent(&block)
        end
        return self
      else
        to_enum(:each_parent)
      end
    end

    def parents
      return each_parent.to_a
    end

    alias ancestors parents
    alias each_ancestor each_parent

    alias traverse each_obj

    def descendants
      return each_descendant.to_a
    end

    if API_VERSION < API_VERSION_2_0 then
      def distances
        distances_count = self[:distances_count]
        if distances_count == 0 then
          return []
        else
          return self[:distances].read_array_of_pointer(distances_count).collect { |p|
            d = Distances::new(p)
            d.instance_variable_set(:@topology, @topology)
            d
          }
        end
      end
    end

    def infos
      infos_count = self[:infos_count]
      if infos_count == 0 then
        return []
      else
        inf_array = infos_count.times.collect { |i|
          o = ObjInfo::new(self[:infos] + i*ObjInfo.size)
        }
	inf_h = {}
	inf_array.each { |e| inf_h[e[:name].to_sym] = e[:value] if e[:name] }
	return inf_h
      end
    end

    def each_info(*args, &block)
      return infos.each(*args, &block)
    end

    def attr
      at = self[:attr]
      return nil if at.to_ptr.null?
      t = self[:type]
      case t
      when :OBJ_GROUP
        return at[:group]
      when :OBJ_PCI_DEVICE
        return at[:pcidev]
      when :OBJ_BRIDGE
        return at[:bridge]
      when :OBJ_OS_DEVICE
        return at[:osdev]
      else
	if API_VERSION >= API_VERSION_2_0 then
          return at[:numanode] if t == :OBJ_NUMANODE
        end
        return at[:cache] if self.is_a_cache?
      end
      return nil
    end

    ObjType.symbols[0..-1].each { |sym|
      suffix = sym.to_s[4..-1].downcase
      methname = "is_a_#{suffix}?"
      define_method(methname) {
        return type == sym
      }
    }

    if API_VERSION >= API_VERSION_2_0 then
      def is_a_cache?
        (Hwloc::OBJ_L1CACHE..Hwloc::OBJ_L3ICACHE).include?(ObjType[type])
      end
    end

  end

end
