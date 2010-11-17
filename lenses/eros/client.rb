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
Postmark.api_key = "782667ec-e8dc-4c6d-a225-7432cc3451e4" if defined? Postmark

def perform_mass_index!
  start = Time.now
  Convex::Eros::Lens.info("Beginning re-index (theme->term+wcount->rate->evaluate)...")
  %w(theme term rate evaluate).each do |action|
    perform_mass action
  end
  minutes = (Time.now - start) / 60.0
  body = "In %d hours %.1f minutes" % [minutes / 60.0, minutes % 60.0]
  
  Convex::Eros::Lens.info("Re-index completed #{body.downcase}")
  message               = TMail::Mail.new
  message.from          = %w(general@styledon.com)
  message.to            = %w(dev@styledon.com)
  message.content_type  = "text/html"
  message.tag           = "convex/eros/client"
  message.subject       = "Re-index complete"
  message.body          = body
  begin
    Postmark.send_through_postmark(message)
  rescue
    Convex::Eros::Lens.warn("Failed to send email: #{$!}")
  end
end

def perform_mass(method)
  message               = TMail::Mail.new
  message.from          = %w(general@styledon.com)
  message.to            = %w(dev@styledon.com)
  message.content_type  = "text/html"
  message.tag           = "convex/eros/client"
  
  name = method.to_s.split('_').first
  start, failure = Time.now, false
  Convex::Eros::Lens.info("Beginning #{name}...")
  begin
    Convex::Eros::Lens.send("#{method}_all!".to_sym)
    message.subject = "#{name.capitalize} complete"
  rescue
    message.subject = "#{name.capitalize} FAILED!"
    Convex::Eros::Lens.warn("Convex::Eros::Lens.#{method}_all! failed because: #{$!}\n\n" << $!.backtrace.join("\n"))
    failure = "\n\n<p><strong>#{$!}</strong></p>" << "<ul>" << $!.backtrace.collect { |line| "<li>#{line}</li>" }.join("\n") << "</ul>"
  end
  minutes = (Time.now - start) / 60.0
  time = "%d hours %.1f minutes" % [minutes / 60.0, minutes % 60.0]
  body = "#{name.capitalize} of #{Convex::Eros::Lens.count} users #{failure ? 'FAILED' : 'completed'} after #{time}"
  Convex::Eros::Lens.info(body)
  message.body = "<p>#{body}</p>"
  message.body << failure if failure
  begin
    Postmark.send_through_postmark(message)
    Convex::Eros::Lens.debug("Sent email to #{message.to.join(', ')}")
  rescue
    Convex::Eros::Lens.warn("Failed to send email: #{$!}")
  end
end

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

### Indexing ###
#   Done to reset or initialize data
elsif ARGV.first == 'index_all!'
  perform_mass_index!
  
### Testing ###
#   Done at a regular interval 
elsif ARGV.first == 'vs'
  ARGV.shift
  ply = Convex::Eros::User.new(ARGV.shift)
  opp = Convex::Eros::User.new(ARGV.shift)
  puts "T = %.8f" % ply.tanimoto_against(opp)
  puts "P = %.8f" % ply.pearson_against(opp)
elsif ARGV.first == 'group'
  ARGV.shift
  users = ARGV.collect { |id| Convex::Eros::User.new(id) }
  k = 10
  puts "K(#{k}) = %s" % Convex::Eros::User.kcluster(users, k).inspect
elsif ARGV.first == 'test!'
  ARGV.shift
  Convex::Eros::Lens.test!(ARGV.shift)
elsif ARGV.first == 'test_all!'
  perform_mass :test
  
### Rating ###
elsif ARGV.first == 'rate!'
  ARGV.shift
  Convex::Eros::Lens.rate!(ARGV.shift)
elsif ARGV.first == 'rate_all!'
  perform_mass :rate
  
### Evaluation ###
elsif ARGV.first == 'evaluate!'
  ARGV.shift
  Convex::Eros::Lens.evaluate!(ARGV.shift)
elsif ARGV.first == 'evaluate_all!'
  perform_mass :evaluate

### Words ###
elsif ARGV.first == 'term!'
  ARGV.shift
  Convex::Eros::Lens.term!(ARGV.shift)
elsif ARGV.first == 'term_all!'
  perform_mass :term

### Word Counts ###
elsif ARGV.first == 'wcounts'
  ARGV.shift
  key, i = Convex::Eros::Lens.redis_key_for_user_word_counts(ARGV.shift), 1
  words = Convex.db.zrange(key, 0, Convex.db.zcard(key))
  puts "#{words.count} words total"
  words.each do |word|
    puts "#{i}.".ljust(6) << ' ' << word.ljust(16) << ' ' << Convex.db.zscore(key, word)
    i += 1
  end
  puts "#{words.count} words total"
elsif ARGV.first == 'wcount!'
  ARGV.shift
  Convex::Eros::Lens.wcount!(ARGV.shift)
elsif ARGV.first == 'wcount_all!'
  perform_mass :wcount
  
### Topics ###
elsif ARGV.first == 'theme!'
  ARGV.shift
  Convex::Eros::Lens.theme!(ARGV.shift)
elsif ARGV.first == 'theme_all!'
  perform_mass :theme

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
  best_ids = (lens.best_n_ids_and_scores_for_id(n, x_id, { :method => :ratings, :integerize_ids => true }) | lens.best_n_ids_and_scores_for_id(n, y_id, { :method => :similarities, :integerize_ids => true }))
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
  max_x += 0.1; max_y += 0.1
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