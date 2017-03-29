module Hwloc
  CpubindFlags = enum( :cpubin_flags, [
    :CPUBIND_PROCESS,   1<<0,
    :CPUBIND_THREAD,    1<<1,
    :CPUBIND_STRICT,    1<<2,
    :CPUBIND_NOMEMBIND, 1<<3
  ] )

  attach_function :hwloc_set_cpubind, [:topology, :cpuset, :int], :int
  attach_function :hwloc_get_cpubind, [:topology, :cpuset, :int], :int
  attach_function :hwloc_set_proc_cpubind, [:topology, :pid_t, :cpuset, :int], :int
  attach_function :hwloc_get_proc_cpubind, [:topology, :pid_t, :cpuset, :int], :int
  attach_function :hwloc_set_thread_cpubind, [:topology, :pthread_t, :cpuset, :int], :int
  attach_function :hwloc_get_thread_cpubind, [:topology, :pthread_t, :cpuset, :int], :int
  attach_function :hwloc_get_last_cpu_location, [:topology, :cpuset, :int], :int
  attach_function :hwloc_get_proc_last_cpu_location, [:topology, :pid_t, :cpuset, :int], :int

  class BindError < Error
  end

  class CpubindError < BindError
  end

  class Topology

    def set_cpubind(cpuset, flags)
      err = Hwloc.hwloc_set_cpubind(@ptr, cpuset, flags)
      raise CpubindError if err == -1
      return self
    end

    def get_cpubind(flags)
      cpuset = Cpuset::new
      err = Hwloc.hwloc_get_cpubind(@ptr, cpuset, flags)
      raise CpubindError if err == -1
      return cpuset
    end

    def set_proc_cpubind(pid, cpuset, flags)
      err = Hwloc.hwloc_set_proc_cpubind(@ptr, pid, cpuset, flags)
      raise CpubindError if err == -1
      return self
    end

    def get_proc_cpubind(pid, flags)
      cpuset = Cpuset::new
      err = Hwloc.hwloc_get_proc_cpubind(@ptr, pid, cpuset, flags)
      raise CpubindError if err == -1
      return cpuset
    end

    def set_thread_cpubind(thread, cpuset, flags)
      err = Hwloc.hwloc_set_thread_cpubind(@ptr, thread, cpuset, flags)
      raise CpubindError if err == -1
      return self
    end

    def get_thread_cpubind(thread, flags)
      cpuset = Cpuset::new
      err = Hwloc.hwloc_get_thread_cpubind(@ptr, thread, cpuset, flags)
      raise CpubindError if err == -1
      return cpuset
    end

    def get_last_cpu_location(flags)
      cpuset = Cpuset::new
      err = Hwloc.hwloc_get_last_cpu_location(@ptr, cpuset, flags)
      raise CpubindError if err == -1
      return cpuset
    end

    def get_proc_last_cpu_location(pid, flags)
      cpuset = Cpuset::new
      err = Hwloc.hwloc_get_proc_last_cpu_location(@ptr, pid, cpuset, flags)
      raise CpubindError if err == -1
      return cpuset
    end

  end

end
