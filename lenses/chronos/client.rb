require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'convex')
require File.join(File.dirname(__FILE__), 'lens')

Convex.boot!
ARGV.shift

if ARGV.first == 'ping'
  Convex::Chronos::Lens.ping
elsif ARGV.first == 'move'
  ARGV.shift
  Convex::Chronos::Lens.move_data(ARGV.shift, ARGV.shift)
end