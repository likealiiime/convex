module Convex
  module Logging
    @@log = nil
    @@log_should_debug = false
    
    def self.open_log_with_name(name)
      @@log ||= File.open(File.join(Convex::LOG_PATH, "#{name}.log"), 'a')
      @@log.puts "\n\n"
    end
    
    def time_for_log
      Time.now.strftime("%b %d %y %I:%M:%S%p")
    end

    def log_newline; log; end
    
    def log(message='', extra_stream=$stdout)
      s = "[#{time_for_log}] " << message.to_s
      @@log.puts(s) if @@log
      extra_stream.puts(s) if extra_stream
    end
    
    def force_debug_logging
      @@log_should_debug = true
      #debug "Debug logging forced"
    end
    
    def log_should_debug?
      @@log_should_debug || Convex.env.development?
    end
    
    def debug(message='')
      log "--- " << message.to_s if log_should_debug?
    end
    
    def info(message='')
      log "+++ " << message.to_s
    end
    
    def warn(message='')
      log "!!! " << message.to_s
    end
    
    def error(message='')
      log("/!\\ " << message.to_s, $stderr)
    end
    
    def log_flush
      @@log.flush
    end
  end
  
  module CustomizedLogging
    def log_preamble; Class === self ? self.name : self.class.name; end
    %w(debug info warn error).each do |level|
      class_eval "def #{level}(message=''); Convex.#{level}(log_preamble.to_s << ': ' << message.to_s); end"
    end
    def log_newline; Convex.log_newline; end
    def log_flush; Convex.log_flush; end
  end
end