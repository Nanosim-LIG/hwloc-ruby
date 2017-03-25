module Hwloc

  typedef :pointer, :bitmap
  typedef :bitmap, :cpuset
  typedef :bitmap, :nodeset

  attach_function :hwloc_bitmap_alloc, [], :bitmap
  attach_function :hwloc_bitmap_free, [:bitmap], :void

  attach_function :hwloc_bitmap_dup, [:bitmap], :bitmap

  attach_function :hwloc_bitmap_snprintf, [:pointer, :size_t, :bitmap], :int
  attach_function :hwloc_bitmap_sscanf, [:bitmap, :pointer], :int
  attach_function :hwloc_bitmap_list_snprintf, [:pointer, :size_t, :bitmap], :int
  attach_function :hwloc_bitmap_list_sscanf, [:bitmap, :pointer], :int

  attach_function :hwloc_bitmap_zero, [:bitmap], :void
  attach_function :hwloc_bitmap_fill, [:bitmap], :void
  attach_function :hwloc_bitmap_only, [:bitmap, :uint], :void
  attach_function :hwloc_bitmap_allbut, [:bitmap, :uint], :void

  attach_function :hwloc_bitmap_set, [:bitmap, :uint], :void
  attach_function :hwloc_bitmap_clr, [:bitmap, :uint], :void

  attach_function :hwloc_bitmap_set_range, [:bitmap, :uint, :int], :void
  attach_function :hwloc_bitmap_clr_range, [:bitmap, :uint, :int], :void

  attach_function :hwloc_bitmap_singlify, [:bitmap], :void

  attach_function :hwloc_bitmap_to_ulong, [:bitmap], :ulong
  attach_function :hwloc_bitmap_to_ith_ulong, [:bitmap, :uint], :ulong
  attach_function :hwloc_bitmap_isset, [:bitmap, :uint], :int
  attach_function :hwloc_bitmap_iszero, [:bitmap], :int
  attach_function :hwloc_bitmap_isfull, [:bitmap], :int
  attach_function :hwloc_bitmap_first, [:bitmap], :int
  attach_function :hwloc_bitmap_next, [:bitmap, :int], :int
  attach_function :hwloc_bitmap_last, [:bitmap], :int
  attach_function :hwloc_bitmap_weight, [:bitmap], :int

  attach_function :hwloc_bitmap_or, [:bitmap, :bitmap, :bitmap], :void
  attach_function :hwloc_bitmap_and, [:bitmap, :bitmap, :bitmap], :void
  attach_function :hwloc_bitmap_andnot, [:bitmap, :bitmap, :bitmap], :void
  attach_function :hwloc_bitmap_xor, [:bitmap, :bitmap, :bitmap], :void
  attach_function :hwloc_bitmap_not, [:bitmap, :bitmap], :void

  attach_function :hwloc_bitmap_intersects, [:bitmap, :bitmap], :int
  attach_function :hwloc_bitmap_isincluded, [:bitmap, :bitmap], :int
  attach_function :hwloc_bitmap_isequal, [:bitmap, :bitmap], :int
  attach_function :hwloc_bitmap_compare_first, [:bitmap, :bitmap], :int
  attach_function :hwloc_bitmap_compare, [:bitmap, :bitmap], :int

  class Bitmap
    include Enumerable
    attr_reader :ptr

    def initialize( *args )
      if args.length == 0 then
        @ptr = FFI::AutoPointer::new( Hwloc.hwloc_bitmap_alloc, Hwloc.method(:hwloc_bitmap_free) )
      elsif args.length == 1 then
        arg = args[0]
        if arg.kind_of?( Bitmap ) then
          @ptr = FFI::AutoPointer::new( Hwloc.hwloc_bitmap_dup(arg.ptr), Hwloc.method(:hwloc_bitmap_free) )
        elsif arg.kind_of?( String ) then
          s_ptr = FFI::MemoryPointer::from_string(arg)
          @ptr = FFI::AutoPointer::new( Hwloc.hwloc_bitmap_alloc, Hwloc.method(:hwloc_bitmap_free) )
          Hwloc.hwloc_bitmap_sscanf(@ptr,s_ptr)
        elsif arg.kind_of?( Array ) then
          list = []
          arg.each { |e|
            if e.kind_of?(Range) then
              if e.last == Float::INFINITY then
                list << "#{e.first}-"
              else
                list << "#{e.first}-#{e.last - (e.exclude_end? ? 1 : 0)}"
              end
            else
              list << e.to_s
            end
          }
          str = list.join(",")
          s_ptr = FFI::MemoryPointer::from_string(str)
          @ptr = FFI::AutoPointer::new( Hwloc.hwloc_bitmap_alloc, Hwloc.method(:hwloc_bitmap_free) )
          Hwloc.hwloc_bitmap_list_sscanf(@ptr,s_ptr)
        elsif arg.kind_of?( Range ) then
          if arg.last == Float::INFINITY then
            str = "#{arg.first}-"
          else
            str = "#{arg.first}-#{arg.last - (arg.exclude_end? ? 1 : 0)}"
          end
          s_ptr = FFI::MemoryPointer::from_string(str)
          @ptr = FFI::AutoPointer::new( Hwloc.hwloc_bitmap_alloc, Hwloc.method(:hwloc_bitmap_free) )
          Hwloc.hwloc_bitmap_list_sscanf(@ptr,s_ptr)
        end
      end
    end

    def dup
      return Bitmap::new( self )
    end

    def to_s
      size = Hwloc.hwloc_bitmap_snprintf(nil, 0, @ptr)
      s_ptr = FFI::MemoryPointer::new(size+1)
      Hwloc.hwloc_bitmap_snprintf(s_ptr, size+1, @ptr)
      s_ptr.read_string
    end

    def to_a
      size = Hwloc.hwloc_bitmap_list_snprintf(nil, 0, @ptr)
      s_ptr = FFI::MemoryPointer::new(size+1)
      Hwloc.hwloc_bitmap_list_snprintf(s_ptr, size+1, @ptr)
      str = s_ptr.read_string
      str.split(",").collect { |e|
        if e.match("-") then
          rgs = e.split("-")
          if rgs.length == 1 then
            en = Float::INFINITY
          else
            en = rgs[1].to_i
          end
          Range::new(rgs[0].to_i,en)
        else
          e.to_i
        end
      }
    end

    def to_i
      return to_s.to_i(16)
    end

    def zero!
      Hwloc.hwloc_bitmap_zero(@ptr)
      return self
    end

    alias clear zero!

    def fill!
      Hwloc.hwloc_bitmap_fill(@ptr)
      return self
    end

    def only!(indx)
      Hwloc.hwloc_bitmap_only(@ptr, indx)
      return self
    end

    def all_but!(indx)
      Hwloc.hwloc_bitmap_allbut(@ptr, indx)
      return self
    end

    def set(indx, val)
      if val then
        Hwloc.hwloc_bitmap_set(@ptr, indx)
      else
        Hwloc.hwloc_bitmap_clr(@ptr, indx)
      end
      return val
    end

    def set_range(indx, val)
      b = indx.first
      if indx.last == Float::INFINITY then
        e = -1
      else
        e = indx.last
        e = e - 1 if indx.exclude_end?
      end
      if val then
        Hwloc.hwloc_bitmap_set_range(@ptr, b, e)
      else
        Hwloc.hwloc_bitmap_clr_range(@ptr, b, e)
      end
      return val
    end

    private :set_range, :set

    def []=(indx, val)
      if indx.kind_of?(Range) then
        set_range(indx, val)
      else
        set(indx, val)
      end
    end

    def [](indx)
      if Hwloc.hwloc_bitmap_isset(@ptr, indx) != 0 then
        return true
      else
        return false
      end
    end

    def singlify!
      Hwloc.hwloc_bitmap_singlify(@ptr)
      return self
    end

    def zero?
      if Hwloc.hwloc_bitmap_iszero(@ptr) != 0 then
        return true
      else
        return false
      end
    end

    alias empty? zero?

    def full?
      if Hwloc.hwloc_bitmap_isfull(@ptr) != 0 then
        return true
      else
        return false
      end
    end

    def first
      f = Hwloc.hwloc_bitmap_first(@ptr)
      return nil if f == -1
      return f
    end

    def last
      f = Hwloc.hwloc_bitmap_last(@ptr)
      if f == -1 then
        if full? then
          return Float::INFINITY
        else
          return nil
        end
      end
      return f
    end

    def weight
      w = Hwloc.hwloc_bitmap_weight(@ptr)
      return Float::INFINITY if w == -1
      return w
    end

    alias size weight

    def each
      if block_given? then
        indx = -1
        while (indx = Hwloc.hwloc_bitmap_next(@ptr, indx) ) != -1 do
          yield indx
        end
        return self
      else
        return to_enum(:each)
      end 
    end

    def &(other)
      res = Bitmap::new
      Hwloc.hwloc_bitmap_and(res.ptr, @ptr, other.ptr)
      return res
    end

    alias intersection &

    def |(other)
      res = Bitmap::new
      Hwloc.hwloc_bitmap_or(res.ptr, @ptr, other.ptr)
      return res
    end

    alias + |

    alias union |

    def ^(other)
      res = Bitmap::new
      Hwloc.hwloc_bitmap_xor(res.ptr, @ptr, other.ptr)
      return res
    end

    def ~
      res = Bitmap::new
      Hwloc.hwloc_bitmap_not(res.ptr, @ptr)
      return res
    end

    def -(other)
      res = Bitmap::new
      Hwloc.hwloc_bitmap_andnot(res.ptr, @ptr, other.ptr)
      return res
    end

    def ==(other)
      return Hwloc.hwloc_bitmap_isequal(@ptr, other.ptr) != 0
    end

    def include?(other)
      return Hwloc.hwloc_bitmap_isincluded(other.ptr, @ptr) != 0
    end

    alias >= include?

    def >(other)
      return self >= other && !(self == other)
    end

    def included?(other)
      return Hwloc.hwloc_bitmap_isincluded(@ptr, other.ptr) != 0
    end

    alias <= included?

    def <(other)
      return self <= other && !(self == other)
    end

    def intersect?(other)
      return Hwloc.hwloc_bitmap_intersects(@ptr, other.ptr) != 0
    end

    def disjoint?(other)
      return Hwloc.hwloc_bitmap_intersects(@ptr, other.ptr) == 0
    end

    def compare_first(other)
      return Hwloc.hwloc_bitmap_compare_first(@ptr, other.ptr) == 0
    end

    def compare(other)
      return Hwloc.hwloc_bitmap_compare(@ptr, other.ptr) == 0
    end

  end

end
