#!/usr/bin/env ruby
_here = File.dirname(__FILE__)
require File.join(_here, '..', '..', 'lib', 'convex')
require File.join(_here, 'lens')
require 'httparty'
require 'fileutils'

Convex.boot!
#Convex.force_debug_logging!
ARGV.shift

def puts_ordered_ids_and_numbers(set, no_data_message="There does not seem to be enough data!")
  if set.count > 0
    i = 1
    set.each do |id, x|
      puts "%s#%d:\t%d" % ["#{i}.".ljust(5), id, x]
      i += 1
    end
  else
    Convex::Eros::Lens.warn no_data_message
  end
end

if ARGV.first == 'count'
  ARGV.shift
  ARGV.each { |id|
    key = Convex::Eros::User.redis_key_for id
    puts "##{id}:\t#{Convex.db.scard(key)}"
  }
elsif ARGV.first == 'most'
  ARGV.shift
  puts_ordered_ids_and_numbers Convex::Eros::Lens.n_ids_and_counts_with_most_data(10)
elsif ARGV.first == 'mostx'
  ARGV.shift
  puts_ordered_ids_and_numbers Convex::Eros::Lens.n_ids_and_counts_with_most_data(10, ARGV)
elsif ARGV.first == 'test'
  ARGV.shift
  ply = Convex::Eros::User.new(ARGV.shift)
  opp = Convex::Eros::User.new(ARGV.shift)
  ply.tanimoto_against opp
elsif ARGV.first == 'index'
  ARGV.shift
  Convex::Eros::Lens.index_tests_for_id(ARGV.shift)
elsif ARGV.first == 'index_all!'
  Convex::Eros::Lens.index_all_tests!
elsif ARGV.first == 'regenerate_all_topics!'
  Convex::Eros::Lens.regenerate_all_topics!
elsif ARGV.first == 'best'
  ARGV.shift
  my_id = ARGV.shift
  set = Convex::Eros::Lens.best_n_ids_and_scores_for_id(10, my_id)
  if set.count > 0
    i = 1
    set.each do |match_id, score|
      puts "%s#%d:\t%.4f" % ["#{i}.".ljust(5), match_id, score.to_f]
      i += 1
    end
  else
    Convex::Eros::Lens.warn "User ##{my_id} is not indexed!"
  end
elsif ARGV.first == 'prefspace'
  ARGV.shift
  lens = Convex::Eros::Lens
  
  n, i, extreme_n = 100, 0, 5
  x_id,x, y_id,y = ARGV.shift,[], ARGV.shift,[]
  max_x, max_y = 0, 0
  best_ids = (lens.best_n_ids_and_scores_for_id(n, x_id, :integerize_ids) | lens.best_n_ids_and_scores_for_id(n, y_id, :integerize_ids))[0...n].sort { |a,b| a.last <=> b.last }.collect(&:first)
  labels = ['c,63A7FF,0,-1,10']
  best_ids.each { |user_id|
    next if user_id == x_id.to_i || user_id == y_id.to_i
    key = lens.redis_key_for_user_test_index(user_id)
    
    _x = lens.score_for_player_id_against_opponent_id(user_id, x_id)
    x << _x
    max_x = _x if _x > max_x
    
    _y = lens.score_for_player_id_against_opponent_id(user_id, y_id)
    y << _y
    max_y = _y if _y > max_y
    
    #labels << "A#{user_id},888888,0,#{i},9" if i < extreme_n || i > (n - extreme_n)
    i += 1
  }
  now = Time.now
  params = {
    :cht  => 's',
    :chs  => '547x547',
    :chma => '25,25,25,25',
    :chtt => "##{x_id} vs. ##{y_id} - Prefspace of Best #{n}|#{now.strftime('%b %d, %Y at %I:%M:%S %p')}",
    :chd  => 't:' << x.join(',') << '|' << y.join(','),
    :chds => "0,#{max_x},0,#{max_y}",
    :chm  => labels.join('|'),
    :chxt => 'x,y,r,t,x,y,x,y',
    :chxr => (0..3).collect { |i| "#{i},0,#{[max_y,max_y].max},0.1" }.join('|'),
    :chxl => "4:|Least Like ##{x_id}|Most Like ##{x_id}|5:|Least Like ##{y_id}|Most Like ##{y_id}|6:|User ##{x_id}|7:|User ##{y_id}",
    :chxp => "6,50|7,50",
    :chxs => '6,000000,12|7,000000,12',
    :chg  => "50,50"
  }
  response = HTTParty.post("http://chart.apis.google.com/chart", { :body => params })
  path = File.join(Convex::TMP_PATH, 'eros', 'prefspace')
  FileUtils.mkdir_p(path)
  path = File.join(path, "#{now.to_i}_#{x_id}vs#{y_id}.")
  if response.code == 200
    File.open(path << 'png', 'w') { |f| f.write response.body }
    lens.info "Wrote chart PNG to #{path}"
  else
    File.open(path << 'html', 'w') { |f| f.write response.body }
    lens.warn "Request failed! Wrote HTML response to #{path}"
  end
else
  raise ArgumentError.new("Unknown Eros client command: #{ARGV.join(' ')}")
end