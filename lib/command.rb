module Convex
  class Command
    extend Convex::CustomizedLogging
    @@pidfile = nil
    
    def self.[](the_name); Convex.const_get("#{the_name}Command"); end
    def self.start!; end
    def self.stop!
      warn "Stopping..."
      debug stop_command
      result = `#{stop_command}`
      warn "Result of stop: #{result}"
      log_status
    end
    def self.log_status
      a = running? ? [:info, 'IS'] : [:warn, 'is NOT']
      send(a[0], "#{@@name} #{a[1]} running")
    end
    def self.running?; @@pidfile && File.exists?(@@pidfile); end
  end
  
  class DaemonizedCommand < Convex::Command
    @@executable, @@name = nil, nil
    def self.start_command; "#{File.join(Convex::ROOT_PATH, @@executable)} start -- #{Convex.environment}"; end
    def self.stop_command; "#{File.join(Convex::ROOT_PATH, @@executable)} stop"; end
    def self.executable; @@executable; end
    def self.name; @@name; end
  end
  
  class ConvexCommand < Convex::DaemonizedCommand
    @@name, @@executable, @@pidfile = :Convex, 'convexd', File.join(File.dirname(__FILE__), '..', 'pids', 'convexd.pid')
  end
  class ChronosCommand < Convex::DaemonizedCommand
    @@name, @@executable, @@pidfile = :Chronos, 'chronosd', File.join(File.dirname(__FILE__), '..', 'pids', 'chronosd.pid')
  end
  class RedisCommand < Convex::Command
    @@name, @@bin_path, @@conf, @@pidfile = :Redis, nil, nil, File.join(File.dirname(__FILE__), '..', 'pids', 'redis.pid')
    def self.start_command; "#{@@bin_path}redis-server #{@@conf}"; end
    def self.stop_command; "#{@@bin_path}redis-cli -p 6379 shutdown"; end
    def self.bin_path=(bp); @@bin_path ||= bp; end
    def self.conf=(c); @@conf ||= c; end
  end
end