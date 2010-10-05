#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'convex')
require File.join(File.dirname(__FILE__), 'lens')

Convex.boot!
ARGV.shift

if ARGV.first == 'ping'
  Convex::Chronos::Lens.ping
elsif ARGV.first == 'move'
  ARGV.shift
  Convex::Chronos::Lens.move_data(ARGV.shift, ARGV.shift)
elsif ARGV.first == 'index'
  Convex::Chronos::Lens.index_ids!
elsif ARGV.first == 'id'
  ARGV.shift
  $stdout << Convex::Chronos::Lens.id_datum_json(ARGV.shift)
elsif ARGV.first == 'last'
end