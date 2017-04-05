module Hwloc

  attach_function :hwloc_topology_export_xml, [:topology, :string], :int
  attach_function :hwloc_topology_export_xmlbuffer, [:topology, :pointer, :pointer], :int
  attach_function :hwloc_free_xmlbuffer, [:topology, :pointer], :void

  callback :hwloc_topology_set_userdata_export_callback_callback, [:pointer, :topology, Obj.ptr], :void
  attach_function :hwloc_topology_set_userdata_export_callback, [:topology, :hwloc_topology_set_userdata_export_callback_callback], :void

  attach_function :hwloc_export_obj_userdata, [:pointer, :topology, Obj.ptr, :string, :pointer, :size_t], :int
  attach_function :hwloc_export_obj_userdata_base64, [:pointer, :topology, Obj.ptr, :string, :pointer, :size_t], :int

  callback :hwloc_topology_set_userdata_import_callback_callback, [:topology, Obj.ptr, :string, :pointer, :size_t], :void
  attach_function :hwloc_topology_set_userdata_import_callback, [:topology, :hwloc_topology_set_userdata_import_callback_callback], :void

  TopologyExportSyntheticFlags = enum( FFI::find_type(:ulong), :topology_export_synthetic_flags, [
    :TOPOLOGY_EXPORT_SYNTHETIC_FLAG_NO_EXTENDED_TYPES, 1<<0,
    :TOPOLOGY_EXPORT_SYNTHETIC_FLAG_NO_ATTRS, 1<<1
  ] )

  attach_function :hwloc_topology_export_synthetic, [:topology, :pointer, :size_t, :uint], :int

  class ExportError < TopologyError
  end

  class Topology

    def export_xml(xmlpath)
      err = Hwloc.hwloc_topology_export_xml(@ptr, xmlpath)
      raise ExportError if err == -1
      return self
    end

    def export_xmlbuffer
      data_p = FFI::MemoryPointer::new(:pointer)
      count_p = FFI::MemoryPointer::new(:int)
      err = Hwloc.hwloc_topology_export_xmlbuffer(@ptr, data_p, count_p)
      raise ExportError if err == -1
      xmlbuffer_p = data_p.read_pointer.slice(0, count_p.read_int)
      return FFI::AutoPointer::new(xmlbuffer_p, self.method(:free_xmlbuffer))
    end

    def free_xmlbuffer(pointer)
      Hwloc.hwloc_free_xmlbuffer(@self, pointer)
    end

    private :free_xmlbuffer

    def export_synthetic(flags = 0)
      str_ptr = FFI::MemoryPointer::new(:char, 2048)
      err = Hwloc.hwloc_topology_export_synthetic(@ptr, str_ptr, str_ptr.size, flags)
      raise ExportError, "Topology not symetric" if err == -1
      return str_ptr.read_string
    end

    def to_s
      begin
        return export_synthetic
      rescue ExportError
        return super
      end
    end

  end

end
