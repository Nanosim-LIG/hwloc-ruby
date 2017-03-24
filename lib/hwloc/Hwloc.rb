require 'ffi'

module Hwloc
  extend FFI::Library
  ffi_lib 'hwloc'

end
