module Hwloc

  class ObjError < Error
  end

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

  class Distances < Struct
    layout :relative_depth, :uint,
           :nbobjs,         :uint,
           :latency,        :pointer,
           :latency_max,    :float,
           :latency_base,   :float
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
  end

  class ObjMemory < Struct
    layout :total_memory, :uint64,
           :local_memory, :uint64,
           :page_types_len, :uint,
           :page_types, :pointer
  end

  class CacheAttr < Struct
    layout :size,          :uint64,
           :depth,         :uint,
           :linesize,      :uint,
           :associativity, :int,
           :type,          :obj_cache_type
  end

  class GroupAttr < Struct
    layout :depth, :uint
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
    layout :cache,  CacheAttr,
           :group,  GroupAttr,
           :pcidev, PcidevAttr,
           :bridge, BridgeAttr,
           :osdev,  OsdevAttr
  end

  class Obj < Struct
  end

  class Obj
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

    layout *layout_array

    def inspect
      return "<#{self.class}:#{"0x00%x" % (object_id << 1)} type=#{type}#{name ? " name=#{name.inspect}" : ""} logical_index=#{logical_index} ptr=#{to_ptr}>"
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

    alias traverse each_obj

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

    def infos
      infos_count = self[:infos_count]
      if infos_count == 0 then
        return []
      else
        inf_array = infos_count.times.collect { |i|
          o = ObjInfo::new(self[:infos] + i*ObjInfo.size)
        }
	inf_h = {}
	inf_array.each { |e| inf_h[e[:name].to_sym] = e[:value] }
	return inf_h
      end
    end

    def attr
      at = self[:attr]
      return nil if at.to_ptr.null?
      t = self[:type]
      case t
      when :OBJ_CACHE
        return at[:cache]
      when :OBJ_GROUP
        return at[:group]
      when :OBJ_PCI_DEVICE
        return at[:pcidev]
      when :OBJ_BRIDGE
        return at[:bridge]
      when :OBJ_OS_DEVICE
        return at[:osdev]
      end
      return nil
    end

  end

end
