class TopologyTest < BaseTest

  def test_dup
    t = @topology.dup
    t_list = t.each_obj.to_a
    topo_list = @topology.each_obj.to_a
    assert_equal(t_list.size, topo_list.size)
    assert(t_list.first != topo_list.first)
  end

  def test_ignore_type
    t = Hwloc::Topology::new
    t.ignore_type(:OBJ_CORE)
    t.set_xml('./pilipili2.topo.xml')
    t.load
    assert_equal(0, t.each_by_type(Hwloc::OBJ_CORE).to_a.size)
    t = Hwloc::Topology::new
    e = assert_raises(Hwloc::TopologyError) {
      t.ignore_type(:OBJ_PU)
    }
    assert_equal(e.message, "Invalid argument")
  end

  def test_raise_xml
    t = Hwloc::Topology::new
    e = assert_raises(Hwloc::TopologyError) {
      t.set_xml("dummy.xml")
    }
    assert_equal(e.message, "No such file or directory")
  end

  def test_set_get_flags
    t = Hwloc::Topology::new
    if Hwloc::API_VERSION < Hwloc::API_VERSION_2_0
      t.flags = Hwloc::Topology::FLAG_IO_DEVICES
    else
      t.set_io_types_filter(:TYPE_FILTER_KEEP_ALL)
    end
    t.set_xml('./pilipili2.topo.xml')
    t.load
    assert( t.each_obj.count > @topology.each_obj.count )
    if Hwloc::API_VERSION < Hwloc::API_VERSION_2_0
      assert( t.get_flags == Hwloc::Topology::FLAG_IO_DEVICES )
    else
      assert( t.get_type_filter( Hwloc::OBJ_PCI_DEVICE ) == :TYPE_FILTER_KEEP_ALL )
    end
  end

  def test_is_thissystem
    assert_equal(false, @topology.thissystem?)
    t = Hwloc::Topology::new
    t.load
    assert_equal(true, t.thissystem?)
  end

  def test_depth
    assert_equal(8, @topology.depth)
    assert_equal(6, @topology.get_type_depth(:OBJ_CORE))
    assert_equal(:OBJ_CORE, @topology.get_depth_type(6))
    e = assert_raises(Hwloc::TopologyError) {
      @topology.get_depth_type(-1)
    }
    assert_equal(e.message, "Invalid argument")
    assert_equal(Hwloc::TYPE_DEPTH_MULTIPLE, @topology.get_type_depth(:OBJ_CACHE)) if Hwloc::API_VERSION < Hwloc::API_VERSION_2_0
  end

  def test_type_or_above_below_depth
    t = Hwloc::Topology::new
    t.ignore_type(:OBJ_CORE)
    t.set_xml('./pilipili2.topo.xml')
    t.load
    assert_equal(6, t.get_type_or_below_depth(:OBJ_CORE))
    assert_equal(5, t.get_type_or_above_depth(:OBJ_CORE))
  end

  def test_get_nbobjs
    assert_equal(12, @topology.get_nbobjs_by_depth(6))
    assert_equal(12, @topology.get_nbobjs_by_type(:OBJ_CORE))
  end

  def test_each_by_depth
    assert_equal(12, @topology.each_by_depth(6).count)
  end

  def test_each_by_type
    assert_equal(12, @topology.each_by_type(:OBJ_CORE).count)
    if Hwloc::API_VERSION < Hwloc::API_VERSION_2_0 then
      assert_equal(26, @topology.each_by_type(:OBJ_CACHE).count)
    else
      assert_equal(26, @topology.select{ |o| o.is_a_cache? }.count)
    end
    assert_equal(0, @topology.each_by_type(:OBJ_BRIDGE).count)
  end

  def test_each_obj
    assert_equal(67, @topology.each.count)
  end

end
