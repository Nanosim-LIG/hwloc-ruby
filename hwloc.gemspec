Gem::Specification.new do |s|
  s.name = 'hwloc'
  s.version = "0.3.2"
  s.author = "Brice Videau"
  s.email = "brice.videau@imag.fr"
  s.homepage = "https://github.com/Nanosim-LIG/hwloc-ruby"
  s.summary = "hwloc ruby bindings"
  s.description = "hwloc ruby bindings for versions 1.10 onward"
  s.files = Dir['hwloc.gemspec', 'LICENSE', 'README.md', 'lib/**/*']
  s.license = 'BSD-2-Clause'
  s.required_ruby_version = '>= 1.9.3'
  s.add_dependency 'ffi', '~> 1.9', '>=1.9.3'
  s.add_dependency 'ffi-bitmask', '~> 0.1.0', '>=0.1.0'
end
