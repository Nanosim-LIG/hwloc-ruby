class BitmapTest < Minitest::Test

  def test_new
    b = Hwloc::Bitmap::new("0x14")
    assert_equal( [2,4], b.to_a)
    assert_equal( "0x00000014", b.to_s)
    b = Hwloc::Bitmap::new([1,2,5,7,11])
    assert_equal([1..2,5,7,11], b.to_a)
    assert_equal( "0x000008a6", b.to_s)
    assert_equal(b, Hwloc::Bitmap::new(b.to_a))
  end

  def test_dup
    b = Hwloc::Bitmap::new("0x14")
    assert_equal(b, b.dup)
    assert(b.ptr != b.dup.ptr)
  end

  def test_first
    b = Hwloc::Bitmap::new("0x14")
    assert_equal(2, b.first)
    assert_equal(nil, b.zero!.last)
  end

  def test_last
    b = Hwloc::Bitmap::new("0x14")
    assert_equal(4, b.last)
    assert_equal(Float::INFINITY, b.fill!.last)
  end

  def test_accessor
    b = Hwloc::Bitmap::new("0x14")
    assert_equal( false, b[3] )
    b[3] = true
    assert_equal( true, b[3] )
    assert_equal( [2..4], b.to_a)
  end

end
