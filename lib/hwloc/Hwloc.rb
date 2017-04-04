require 'ffi'

module Hwloc
  extend FFI::Library
  ffi_lib 'hwloc'

  attach_function :hwloc_get_api_version, [], :uint

  raise RuntimeError, "Wrong hwloc api version (#{Hwloc.hwloc_get_api_version.to_a(16)})!" if Hwloc.hwloc_get_api_version < 0x00010a00

  attach_function :strerror, [:int], :string

  def self.error_string
    return Hwloc.strerror(FFI::LastError::error)
  end

  class Error < RuntimeError
    def initialize(msg = nil)
      msg = Hwloc.error_string unless msg
      super( msg )
    end
  end

end
