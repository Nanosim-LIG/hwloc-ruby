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
    assert_nil(b.zero!.last)
  end

  def test_last
    b = Hwloc::Bitmap::new("0x14")
    assert_equal(4, b.last)
    assert_equal(Float::INFINITY, b.fill!.last)
  end

  def test_accessor
    b = Hwloc::Bitmap::new("0x14")
    assert_equal(false, b[3])
    b[3] = true
    assert_equal(true, b[3])
    assert_equal([2..4], b.to_a)
  end

  def test_weight
    b = Hwloc::Bitmap::new("0x14")
    assert_equal(2, b.weight)
    b = Hwloc::Bitmap::new([1,2,5,7,11,15..Float::INFINITY])
    assert_equal(Float::INFINITY, b.weight)
  end

  def test_each
    b = Hwloc::Bitmap::new("0x14")
    assert_equal([2,4], b.each.to_a)
    if RUBY_VERSION.scan(/\d+/).collect(&:to_i).first >= 2
      b = Hwloc::Bitmap::new([1,2,5,7,11,15..Float::INFINITY])
      assert_equal([1,2,5,7,11,15,16], b.each.lazy.take(7).force)
    end
  end

  def test_zero
    b = Hwloc::Bitmap::new
    assert(b.zero?)
    b = Hwloc::Bitmap::new("0x14")
    assert(!b.zero?)
    b.zero!
    assert(b.zero?)
  end

  def test_fill_full
    b = Hwloc::Bitmap::new("0x14")
    assert(!b.full?)
    b.fill!
    assert(b.full?)
  end

  def test_only_all_but
    b = Hwloc::Bitmap::new
    b.only!(72)
    assert_equal(1, b.weight)
    assert_equal([72], b.to_a)
    b.all_but!(72)
    assert_equal(Float::INFINITY, b.weight)
    assert_equal([0..71, 73..Float::INFINITY], b.to_a)
    b.singlify!
    assert_equal([0], b.to_a)
  end

  def test_operators
    b1 = Hwloc::Bitmap::new
    b1.only!(72)
    b2 = Hwloc::Bitmap::new
    b2.all_but!(72)
    assert((b1 & b2).empty?)
    assert((b1 | b2).full?)
    assert((b1 + b2).full?)
    b3 = Hwloc::Bitmap::new
    b3.fill!
    assert((b3 - b1) == b2)
    assert((b3 ^ b1) == b2)
    assert(~(b3 - b1) == b1)
  end

  def test_ensemble
    b1 = Hwloc::Bitmap::new([17...25])
    b2 = Hwloc::Bitmap::new([19..20])
    assert(b1.include?(b2))
    assert(b1 >= b2)
    assert(b1 > b2)
    assert(b2.included?(b1))
    assert(b2 <= b1)
    assert(b2 < b1)
    assert(!(b1 < b1))
    assert(b1 <= b1)
    assert(b1.intersect?(b2))
    b3 = Hwloc::Bitmap::new([19..26])
    assert(!b1.include?(b3))
    assert(b1.intersect?(b3))
    b4 = Hwloc::Bitmap::new([25..30])
    assert(!b1.include?(b4))
    assert(!b1.intersect?(b4))
    assert(b1.disjoint?(b4))
  end

  def test_compare
    b1 = Hwloc::Bitmap::new([17...25])
    b2 = Hwloc::Bitmap::new([19..20])
    assert(b1.compare_first(b2) < 0)
    assert(b2.compare_first(b1) > 0)
    assert(b1.compare_first(b1) == 0)
    assert(b1.compare(b2) ==  1)
    assert(b2.compare(b1) == -1)
    assert(b1.compare(b1) ==  0)
    assert((b1 <=> b2) ==  1)
    assert((b2 <=> b1) == -1)
    assert((b1 <=> b1) ==  0)
  end

end
