[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }
require 'minitest/autorun'
require 'hwloc'
require 'ffi'

class BaseTest < Minitest::Test

  def setup
    @topology = Hwloc::Topology::new
    @topology.set_xml('./pilipili2.topo.xml')
    @topology.load
  end

end

require_relative 'Topology/Topology'
require_relative 'Topology/Obj'
