#!/usr/bin/env ruby
_here = File.dirname(__FILE__)
require File.join(_here, '..', '..', 'lib', 'convex')
require File.join(_here, 'lens')
require 'httparty'
require 'fileutils'
require 'postmark'
require 'tmail'

Convex.boot!
#ARGV.shift

command = ARGV.shift.to_s.downcase.strip
case command
when 'tunion'
  n = ARGV.shift; n = n ? n.to_i : 30
  keys = Convex.db.keys 'lens-eros-*_word_counts'
  dest_key = 'lens-eros-tunion_report_tmp'
  Convex.db.zunionstore dest_key, keys, :aggregate => :sum
  top = Convex.db.zrevrange dest_key, 0, n - 1, :with_scores => true # ["word", "count", ...]
  i, document = 1, "Top #{n} words overall:\n"
  top.each do |item|
    if (i - 1) % 2 == 0
      document << "\t#" << "#{(i+1)/2}.".ljust(4) << item.ljust(30)
    else
      document << " (" << item.ljust(6) << " times)\n"
    end
    i += 1
  end
  path = File.join(Convex::TMP_PATH, 'eros', 'report')
  FileUtils.mkdir_p(path)
  File.open(File.join(path, "#{Time.now.to_i}_tunion.txt"), 'w') { |f| f << document }
  puts document
when 'bunion'
  n = ARGV.shift; n = n ? n.to_i : 30
  z = ARGV.shift; z = z ? z.to_i : 5
  keys = Convex.db.keys 'lens-eros-*_word_counts'
  dest_key = 'lens-eros-bunion_report_tmp'
  Convex.db.zunionstore dest_key, keys, :aggregate => :sum
  bottom = Convex.db.zrangebyscore dest_key, z, '+inf', :with_scores => true, :limit => n # ["word", "count", ...]
  i, document = 1, "Bottom #{n} words overall:\n"
  bottom.each do |item|
    if (i - 1) % 2 == 0
      document << "\t#" << "#{(i+1)/2}.".ljust(4) << item.ljust(30)
    else
      document << " (" << item.ljust(6) << " times)\n"
    end
    i += 1
  end
  path = File.join(Convex::TMP_PATH, 'eros', 'report')
  FileUtils.mkdir_p(path)
  File.open(File.join(path, "#{Time.now.to_i}_bunion.txt"), 'w') { |f| f << document }
  puts document
when 'tinter'
  n = ARGV.shift; n = n ? n.to_i : 30
  keys = Convex.db.keys 'lens-eros-*_word_counts'
  dest_key = 'lens-eros-tinter_report_tmp'
  Convex.db.zinterstore dest_key, keys, :aggregate => :sum
  top = Convex.db.zrevrange dest_key, 0, n - 1, :with_scores => true # ["word", "count", ...]
  i, document = 1, "Top #{n} words in common:\n"
  p top
  top.each do |item|
    if (i - 1) % 2 == 0
      document << "\t#" << "#{(i+1)/2}.".ljust(4) << item.ljust(30)
    else
      document << " (" << item.ljust(6) << " times)\n"
    end
    i += 1
  end
  path = File.join(Convex::TMP_PATH, 'eros', 'report')
  FileUtils.mkdir_p(path)
  File.open(File.join(path, "#{Time.now.to_i}_tinter.txt"), 'w') { |f| f << document }
  puts document
end