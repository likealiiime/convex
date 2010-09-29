#!/usr/bin/env ruby
_here = File.dirname(__FILE__)
require File.join(_here, '..', '..', 'lib', 'convex')
require File.join(_here, 'lens')
require 'httparty'
require 'fileutils'

Convex.boot!
Convex.force_debug_logging!
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

def puts_ordered_ids_and_scores(set, no_data_message="User has no data!")
  if set.count > 0
    i = 1
    set.each do |match_id, score|
      puts "%s#%d:\t%.4f" % ["#{i}.".ljust(5), match_id, score.to_f]
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

### Testing ###
elsif ARGV.first == 'vs'
  ARGV.shift
  ply = Convex::Eros::User.new(ARGV.shift)
  opp = Convex::Eros::User.new(ARGV.shift)
  puts "T = %.8f" % ply.tanimoto_against(opp)
  puts "P = %.8f" % ply.pearson_against(opp)
elsif ARGV.first == 'test!'
  ARGV.shift
  Convex::Eros::Lens.test!(ARGV.shift)
elsif ARGV.first == 'test_all!'
  ARGV.shift
  Convex::Eros::Lens.test_all!(ARGV.shift)
  
### Rating ###
elsif ARGV.first == 'rate!'
  ARGV.shift
  Convex::Eros::Lens.rate!(ARGV.shift)
elsif ARGV.first == 'rate_all!'
  ARGV.shift
  Convex::Eros::Lens.rate_all!(ARGV.shift)
  
### Evaluation ###
elsif ARGV.first == 'evaluate!'
  ARGV.shift
  Convex::Eros::Lens.evaluate!(ARGV.shift)
elsif ARGV.first == 'evaluate_all!'
  ARGV.shift
  Convex::Eros::Lens.evaluate_all!

### Topics ###
elsif ARGV.first == 'theme!'
  ARGV.shift
  Convex::Eros::Lens.theme!(ARGV.shift)
elsif ARGV.first == 'theme_all!'
  ARGV.shift
  Convex::Eros::Lens.theme_all!

elsif ARGV.first == 'test_all!'
  Convex::Eros::Lens.test_all!

### Ranking ###
elsif ARGV.first == 'best'
  ARGV.shift
  my_id = ARGV.shift
  puts_ordered_ids_and_scores Convex::Eros::Lens.best_n_ids_and_scores_for_id(10, my_id), "User has not been evaluated!"
elsif ARGV.first == 'bestx'
  ARGV.shift
  my_id = ARGV.shift
  puts_ordered_ids_and_scores Convex::Eros::Lens.best_n_ids_and_scores_for_id(10, my_id, :excluding => ARGV), "User has not been evaluated!"
elsif ARGV.first == 'most'
  ARGV.shift
  puts_ordered_ids_and_numbers Convex::Eros::Lens.n_ids_and_counts_with_most_data(10)
elsif ARGV.first == 'mostx'
  ARGV.shift
  puts_ordered_ids_and_numbers Convex::Eros::Lens.n_ids_and_counts_with_most_data(10, ARGV)

### Prefspace ###
elsif ARGV.first == 'prefspace'
  ARGV.shift
  lens = Convex::Eros::Lens
  
  n, i, extreme_n = 100, 0, 5
  x_id,x, y_id,y = ARGV.shift,[], ARGV.shift,[]
  max_x, max_y = 0, 0
  best_ids = (lens.best_n_ids_and_scores_for_id(n, x_id, { :method => :similarities, :integerize_ids => true }) | lens.best_n_ids_and_scores_for_id(n, y_id, { :method => :similarities, :integerize_ids => true }))
  best_ids = best_ids[0...n].sort { |a,b| a.last <=> b.last }.collect(&:first)
  labels = ['c,63A7FF,0,-1,10']
  
  best_ids.each { |user_id|
    next if user_id == x_id.to_i || user_id == y_id.to_i
    
    _x = lens.similarity_between(user_id, x_id)
    x << _x
    max_x = _x if _x > max_x
    
    _y = lens.similarity_between(user_id, y_id)
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