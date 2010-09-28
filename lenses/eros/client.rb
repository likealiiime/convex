#!/usr/bin/env ruby
_here = File.dirname(__FILE__)
require File.join(_here, '..', '..', 'lib', 'convex')
require File.join(_here, 'lens')
require File.join(_here, 'user')

Convex.boot!
ARGV.shift

def users_from(ids)
end

if ARGV.first == 'count'
  ARGV.shift
  ARGV.each { |id|
    key = Convex::Eros::User.key_for id
    puts "##{id}:\t#{Convex.db.scard(key)}"
  }
elsif ARGV.first == 'test'
  ARGV.shift
  ply = Convex::Eros::User.new(ARGV.shift)
  opp = Convex::Eros::User.new(ARGV.shift)
  ply.tanimoto_against opp
end