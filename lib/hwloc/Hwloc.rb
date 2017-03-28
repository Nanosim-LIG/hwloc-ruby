require 'ffi'

module Hwloc
  extend FFI::Library
  ffi_lib 'hwloc'

  class Error < RuntimeError
  end

end
