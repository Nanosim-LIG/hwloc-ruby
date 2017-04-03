require 'ffi'

module Hwloc
  extend FFI::Library
  ffi_lib 'hwloc'

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
