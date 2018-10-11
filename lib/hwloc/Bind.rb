module Hwloc
  CpubindFlags = bitmask( :cpubind_flags, [
    :CPUBIND_PROCESS,
    :CPUBIND_THREAD,
    :CPUBIND_STRICT,
    :CPUBIND_NOMEMBIND
  ] )

  if API_VERSION < API_VERSION_2_0 then
    MembindPolicy = enum( :membind_policy, [
      :MEMBIND_DEFAULT,    0,
      :MEMBIND_FIRSTTOUCH, 1,
      :MEMBIND_BIND,       2,
      :MEMBIND_INTERLEAVE, 3,
      :MEMBIND_REPLICATE,  4,
      :MEMBIND_NEXTTOUCH,  5,
      :MEMBIND_MIXED,      -1
    ] )
  else
    MembindPolicy = enum( :membind_policy, [
      :MEMBIND_DEFAULT,    0,
      :MEMBIND_FIRSTTOUCH, 1,
      :MEMBIND_BIND,       2,
      :MEMBIND_INTERLEAVE, 3,
      :MEMBIND_NEXTTOUCH,  4,
      :MEMBIND_MIXED,      -1
    ] )
  end

  MembindFlags = bitmask( :membind_flags, [
    :MEMBIND_PROCESS,
    :MEMBIND_THREAD,
    :MEMBIND_STRICT,
    :MEMBIND_MIGRATE,
    :MEMBIND_NOCPUBIND,
    :MEMBIND_BYNODESET
  ] )

  attach_function :hwloc_set_cpubind, [:topology, :cpuset, :cpubind_flags], :int
  attach_function :hwloc_get_cpubind, [:topology, :cpuset, :cpubind_flags], :int
  attach_function :hwloc_set_proc_cpubind, [:topology, :hwloc_pid_t, :cpuset, :cpubind_flags], :int
  attach_function :hwloc_get_proc_cpubind, [:topology, :hwloc_pid_t, :cpuset, :cpubind_flags], :int
  attach_function :hwloc_set_thread_cpubind, [:topology, :hwloc_thread_t, :cpuset, :cpubind_flags], :int
  attach_function :hwloc_get_thread_cpubind, [:topology, :hwloc_thread_t, :cpuset, :cpubind_flags], :int
  attach_function :hwloc_get_last_cpu_location, [:topology, :cpuset, :cpubind_flags], :int
  attach_function :hwloc_get_proc_last_cpu_location, [:topology, :hwloc_pid_t, :cpuset, :cpubind_flags], :int

  class BindError < Error
  end

  class CpubindError < BindError
  end

  class Topology

    def set_cpubind(cpuset, *flags)
      if block_given? then
        oldcpuset = get_cpubind(flags)
        set_cpubind(cpuset, flags)
        yield
        set_cpubind(oldcpuset, flags)
      else
        err = Hwloc.hwloc_set_cpubind(@ptr, cpuset, flags)
        raise CpubindError if err == -1
        return self
      end
    end

    def get_cpubind(*flags)
      cpuset = Cpuset::new
      err = Hwloc.hwloc_get_cpubind(@ptr, cpuset, flags)
      raise CpubindError if err == -1
      return cpuset
    end

    def set_proc_cpubind(pid, cpuset, *flags)
      err = Hwloc.hwloc_set_proc_cpubind(@ptr, pid, cpuset, flags)
      raise CpubindError if err == -1
      return self
    end

    def get_proc_cpubind(pid, *flags)
      cpuset = Cpuset::new
      err = Hwloc.hwloc_get_proc_cpubind(@ptr, pid, cpuset, flags)
      raise CpubindError if err == -1
      return cpuset
    end

    def set_thread_cpubind(thread, cpuset, *flags)
      err = Hwloc.hwloc_set_thread_cpubind(@ptr, thread, cpuset, flags)
      raise CpubindError if err == -1
      return self
    end

    def get_thread_cpubind(thread, *flags)
      cpuset = Cpuset::new
      err = Hwloc.hwloc_get_thread_cpubind(@ptr, thread, cpuset, flags)
      raise CpubindError if err == -1
      return cpuset
    end

    def get_last_cpu_location(*flags)
      cpuset = Cpuset::new
      err = Hwloc.hwloc_get_last_cpu_location(@ptr, cpuset, flags)
      raise CpubindError if err == -1
      return cpuset
    end

    def get_proc_last_cpu_location(pid, *flags)
      cpuset = Cpuset::new
      err = Hwloc.hwloc_get_proc_last_cpu_location(@ptr, pid, cpuset, flags)
      raise CpubindError if err == -1
      return cpuset
    end

  end

  class MembindError < BindError
  end

  if API_VERSION < API_VERSION_2_0 then
    attach_function :hwloc_set_membind_nodeset, [:topology, :nodeset, :membind_policy, :membind_flags], :int
    attach_function :hwloc_get_membind_nodeset, [:topology, :nodeset, :pointer, :membind_flags], :int
    attach_function :hwloc_set_proc_membind_nodeset, [:topology, :hwloc_pid_t, :nodeset, :membind_policy, :membind_flags], :int
    attach_function :hwloc_get_proc_membind_nodeset, [:topology, :hwloc_pid_t, :nodeset, :pointer, :membind_flags], :int
    attach_function :hwloc_set_area_membind_nodeset, [:topology, :pointer, :size_t, :nodeset, :membind_policy, :membind_flags], :int
    attach_function :hwloc_get_area_membind_nodeset, [:topology, :pointer, :size_t, :nodeset, :pointer, :membind_flags], :int
    attach_function :hwloc_alloc_membind_nodeset, [:topology, :size_t, :nodeset, :membind_policy, :membind_flags], :pointer
  end
  attach_function :hwloc_set_membind, [:topology, :bitmap, :membind_policy, :membind_flags], :int
  attach_function :hwloc_get_membind, [:topology, :bitmap, :pointer, :membind_flags], :int
  attach_function :hwloc_set_proc_membind, [:topology, :hwloc_pid_t, :bitmap, :membind_policy, :membind_flags], :int
  attach_function :hwloc_get_proc_membind, [:topology, :hwloc_pid_t, :bitmap, :pointer, :membind_flags], :int
  attach_function :hwloc_set_area_membind, [:topology, :pointer, :size_t, :bitmap, :membind_policy, :membind_flags], :int
  attach_function :hwloc_get_area_membind, [:topology, :pointer, :size_t, :bitmap, :pointer, :membind_flags], :int

  begin
    attach_function :hwloc_get_area_memlocation, [:topology, :pointer, :size_t, :bitmap, :membind_flags], :int
  rescue FFI::NotFoundError
    warn "Missing hwloc_get_area_memlocation support!"
  end

  attach_function :hwloc_alloc, [:topology, :size_t], :pointer
  attach_function :hwloc_alloc_membind, [:topology, :size_t, :bitmap, :membind_policy, :membind_flags], :pointer
  attach_function :hwloc_free, [:topology, :pointer, :size_t], :int

  class Topology

    if API_VERSION < API_VERSION_2_0 then

      def set_membind_nodeset(nodeset, policy, *flags)
        err = Hwloc.hwloc_set_membind_nodeset(@ptr, nodeset, policy, flags)
        raise MembindError if err == -1
        return self
      end

      def get_membind_nodeset(*flags)
        nodeset = Nodeset::new
        policy_p = FFI::MemoryPointer::new(MembindPolicy.native_type)
        err = Hwloc.hwloc_get_membind_nodeset(@ptr, nodeset, policy_p, flags)
        raise MembindError if err == -1
        policy = policy_p.read_int
        return [nodeset, MembindPolicy[policy]]
      end

      def set_proc_membind_nodeset(pid, nodeset, policy, *flags)
        err = Hwloc.hwloc_set_proc_membind_nodeset(@ptr, pid, nodeset, policy, flags)
        raise MembindError if err == -1
        return self
      end

      def get_proc_membind_nodeset(pid, *flags)
        nodeset = Nodeset::new
        policy_p = FFI::MemoryPointer::new(MembindPolicy.native_type)
        err = Hwloc.hwloc_get_proc_membind_nodeset(@ptr, pid, nodeset, policy_p, flags)
        raise MembindError if err == -1
        policy = MembindPolicy[policy_p.read_int]
        return [nodeset, policy]
      end

      def set_area_membind_nodeset(pointer, nodeset, policy, *flags)
        err = Hwloc.hwloc_set_area_membind_nodeset(@ptr, pointer, pointer.size, nodeset, policy, flags)
        raise MembindError if err == -1
        return self
      end

      def get_area_membind_nodeset(pointer, *flags)
        nodeset = Nodeset::new
        policy_p = FFI::MemoryPointer::new(MembindPolicy.native_type)
        err = Hwloc.hwloc_get_area_membind_nodeset(@ptr, pointer, pointer.size, nodeset, policy_p, flags)
        raise MembindError if err == -1
        policy = MembindPolicy[policy_p.read_int]
        return [nodeset, policy]
      end

      def alloc_membind_nodeset(size, nodeset, policy, *flags)
        ptr = Hwloc.hwloc_alloc_membind_nodeset(@ptr, size, nodeset, policy, flags)
        raise MembindError if ptr.null?
        ptr = ptr.slice(0, size)
        return FFI::AutoPointer::new(ptr, self.method(:free))
      end

      def alloc_membind_policy_nodeset(size, nodeset, policy, *flags)
        begin
          return alloc_membind_nodeset(size, nodeset, policy, flags)
        rescue MembindError
          set_membind_nodeset(nodeset, policy, flags)
          ptr = alloc(size)
          ptr.clear if policy != Hwloc::MEMBIND_FIRSTTOUCH
          return ptr
        end
      end

    else

      def set_membind_nodeset(nodeset, policy, *flags)
        flags.push :MEMBIND_BYNODESET
        set_membind(nodeset, policy, *flags)
        return self
      end

      def get_membind_nodeset(*flags)
        flags.push :MEMBIND_BYNODESET
        get_membind(*flags)
      end

      def set_proc_membind_nodeset(pid, nodeset, policy, *flags)
        flags.push :MEMBIND_BYNODESET
        set_proc_membind(pid, nodeset, policy, flags)
        return self
      end

      def get_proc_membind_nodeset(pid, *flags)
        flags.push :MEMBIND_BYNODESET
        get_proc_membind(pid, *flags)
      end

      def set_area_membind_nodeset(pointer, nodeset, policy, *flags)
        flags.push :MEMBIND_BYNODESET
        set_area_membind(pointer, nodeset, policy, *flags)
        return self
      end

      def get_area_membind_nodeset(pointer, *flags)
        flags.push :MEMBIND_BYNODESET
        get_area_membind(pointer, *flags)
      end

      def alloc_membind_nodeset(size, nodeset, policy, *flags)
        flags.push :MEMBIND_BYNODESET
        alloc_membind(size, nodeset, policy, *flags)
      end

      def alloc_membind_policy_nodeset(size, nodeset, policy, *flags)
        flags.push :MEMBIND_BYNODESET
        alloc_membind_policy_nodeset(size, nodeset, policy, *flags)
      end

    end

    def set_membind(set, policy, *flags)
      if block_given? then
        oldset, oldpolicy = get_membind(flags)
        set_membind(set, policy, flags)
        yield
        set_membind(oldset, oldpolicy, flags)
      else
        err = Hwloc.hwloc_set_membind(@ptr, set, policy, flags)
        raise MembindError if err == -1
        return self
      end
    end

    def get_membind(*flags)
      set = Bitmap::new
      policy_p = FFI::MemoryPointer::new(MembindPolicy.native_type)
      err = Hwloc.hwloc_get_membind(@ptr, set, policy_p, flags)
      raise MembindError if err == -1
      policy = policy_p.read_int
      return [set, MembindPolicy[policy]]
    end

    def set_proc_membind(pid, set, policy, *flags)
      err = Hwloc.hwloc_set_proc_membind(@ptr, pid, set, policy, flags)
      raise MembindError if err == -1
      return self
    end

    def get_proc_membind(pid, *flags)
      set = Bitmap::new
      policy_p = FFI::MemoryPointer::new(MembindPolicy.native_type)
      err = Hwloc.hwloc_get_proc_membind(@ptr, pid, set, policy_p, flags)
      raise MembindError if err == -1
      policy = MembindPolicy[policy_p.read_int]
      return [set, policy]
    end

    def set_area_membind(pointer, set, policy, *flags)
      err = Hwloc.hwloc_set_area_membind(@ptr, pointer, pointer.size, set, policy, flags)
      raise MembindError if err == -1
      return self
    end

    def get_area_membind(pointer, *flags)
      set = Bitmap::new
      policy_p = FFI::MemoryPointer::new(MembindPolicy.native_type)
      err = Hwloc.hwloc_get_area_membind(@ptr, pointer, pointer.size, set, policy_p, flags)
      raise MembindError if err == -1
      policy = MembindPolicy[policy_p.read_int]
      return [set, policy]
    end

    if Hwloc.respond_to?(:hwloc_get_area_memlocation)
      def get_area_memlocation(pointer, *flags)
        set = Bitmap::new
        err = Hwloc.hwloc_get_area_memlocation(@ptr, pointer, pointer.size, set, flags)
        raise MembindError if err == -1
        return set
      end
    end

    def alloc(size)
      ptr = Hwloc.hwloc_alloc(@ptr, size)
      raise MembindError if ptr.null?
      ptr = ptr.slice(0, size)
      return FFI::AutoPointer::new(ptr, self.method(:free))
    end

    def alloc_membind(size, set, policy, *flags)
      ptr = Hwloc.hwloc_alloc_membind(@ptr, size, set, policy, flags)
      raise MembindError if ptr.null?
      ptr = ptr.slice(0, size)
      return FFI::AutoPointer::new(ptr, self.method(:free))
    end

    def alloc_membind_policy(size, set, policy, *flags)
      begin
        return alloc_membind(size, set, policy, flags)
      rescue MembindError
        set_membind(set, policy, flags)
        ptr = alloc(size)
        ptr.clear if policy != Hwloc::MEMBIND_FIRSTTOUCH
        return ptr
      end
    end

    def free(pointer)
      Hwloc.hwloc_free(@ptr, pointer, pointer.size)
    end

    private :free

  end

end
