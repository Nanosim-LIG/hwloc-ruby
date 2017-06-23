require 'ffi'
require 'ffi/bitmask'

module Hwloc
  extend FFI::Library

  if ENV['HWLOC_LIBRARY_PATH']
    ffi_lib ENV['HWLOC_LIBRARY_PATH']
  else
    ffi_lib 'hwloc'
  end
  attach_function :hwloc_get_api_version, [], :uint

  API_VERSION = Hwloc.hwloc_get_api_version
  API_VERSION_1_10 = 0x00010a00
  API_VERSION_2_0 = 0x00020000

  raise LoadError, "Wrong hwloc api version (#{API_VERSION.to_s(16)})!" if API_VERSION < 0x00010a00

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
