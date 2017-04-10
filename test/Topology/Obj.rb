class ObjTest < BaseTest

  def test_get_root_obj
    o = @topology.get_root_obj
    assert_equal(@topology, o.topology)
    assert_equal(:OBJ_MACHINE, o.type)
    assert_equal(2, o.arity)
  end

  def test_get_relatives
    o = @topology.get_root_obj
    c1 = o.first_child
    c2 = o.last_child
    assert_equal(@topology, c1.topology)
    assert_equal(:OBJ_NUMANODE, c1.type)
    assert(c1.is_a_numanode?)
    assert(!c1.is_a_core?)
    assert_equal([c1, c2], o.children)
    assert_equal(o, c1.parent)
    assert_equal(c1, c2.previous_sibling)
    assert_equal(c2, c1.next_sibling)
    assert_equal(c1, c2.prev_cousin)
    assert_equal(c2, c1.next_cousin)
  end

  def test_depth
    o = @topology.get_root_obj
    c1 = o.first_child
    assert_equal(o.depth, c1.depth - 1)
  end

  def test_nodeset
    o = @topology.get_root_obj
    n = o.nodeset
    assert_kind_of(Hwloc::Nodeset, n)
    assert_equal([0..1], n.to_a)
    c1 = o.first_child
    c2 = o.last_child
    assert_equal([0], c1.nodeset.to_a)
    assert_equal([1], c2.nodeset.to_a)
    assert_equal(n, c1.nodeset+c2.nodeset)
  end

  def test_cpuset
    o = @topology.get_root_obj
    c = o.cpuset
    assert_kind_of(Hwloc::Cpuset, c)
    assert_equal([0..23], c.to_a)
    c1 = o.first_child
    c2 = o.last_child
    assert_equal([0..5, 12..17], c1.cpuset.to_a)
    assert_equal([6..11, 18..23], c2.cpuset.to_a)
    assert_equal(c, c1.cpuset+c2.cpuset)
  end

  def test_logical_index
    o = @topology.get_root_obj
    assert_equal(0, o.logical_index)
    c1 = o.first_child
    assert_equal(0, c1.logical_index)
    c2 = o.last_child
    assert_equal(1, c2.logical_index)
  end

  def test_each_obj
    o = @topology.get_root_obj
    c1 = o.first_child
    c2 = o.last_child
    o_list = o.each_obj.to_a
    c1_list = c1.each_obj.to_a
    c2_list = c2.each_obj.to_a
    assert_equal(o_list.size, c1_list.size + c2_list.size + 1)
    assert_equal(c1_list.size, c2_list.size)
    assert_equal(6, c1.each_obj.select { |e| e.type == :OBJ_CORE }.size)
    assert_equal(12, c1.each_obj.select { |e| e.type == :OBJ_PU }.size)
    assert_equal(6, c2.each_obj.select { |e| e.type == :OBJ_CORE }.size)
    assert_equal(12, c2.each_obj.select { |e| e.type == :OBJ_PU }.size)
    assert_kind_of(Enumerator, c1.each_obj)
  end

  def test_parents
    o = @topology.get_root_obj
    c1 = o.first_child
    gc1 = c1.first_child
    assert_equal([c1, o], gc1.parents)
  end

  def test_each_child
    cs = @topology.get_root_obj.children
    cs_array = []
    @topology.get_root_obj.each_child { |c|
      cs_array.push c
    }
    assert_equal(cs, cs_array)
  end

  def test_infos
    o = @topology.get_root_obj
    assert_equal({:DMIProductName=>"Precision R7610", :DMIProductVersion=>"01", :DMIBoardVendor=>"Dell Inc.", :DMIBoardName=>"02MGJ2", :DMIBoardVersion=>"A00", :DMIBoardAssetTag=>"", :DMIChassisVendor=>"Dell Inc.", :DMIChassisType=>"23", :DMIChassisVersion=>"", :DMIChassisAssetTag=>"", :DMIBIOSVendor=>"Dell Inc.", :DMIBIOSVersion=>"A05", :DMIBIOSDate=>"01/10/2014", :DMISysVendor=>"Dell Inc.", :Backend=>"Linux", :LinuxCgroup=>"/", :OSName=>"Linux", :OSRelease=>"3.16.0-4-amd64", :OSVersion=>"#1 SMP Debian 3.16.7-ckt25-2+deb8u2 (2016-06-25)", :HostName=>"pilipili2", :Architecture=>"x86_64"}, o.infos)
    h = {}
    o.each_info { |k,v| h[k] = v }
    assert_equal( h, o.infos)
  end

end
