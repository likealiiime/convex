module Convex
  module Logging
    def self.open_log_with_name(name)
      @@log ||= File.open(File.join(File.dirname(__FILE__), '..', 'log', "#{name}.log"), 'a')
      @@log.puts "\n\n"
    end
    
    def time_for_log
      Time.now.strftime("%b %d %y %I:%M:%S%p")
    end

    def log_newline
      puts ""
    end
    
    def log(message='', extra_stream=$stdout)
      s = "[#{time_for_log}] " << message.to_s
      @@log.puts(s)
      extra_stream.puts(s) if extra_stream
    end
    
    def debug(message='')
      log "--- " << message.to_s if env.development?
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
  end
  
  module CustomizedLogging
    def log_preamble; ''; end
    %w(debug info warn error).each do |level|
      class_eval "def #{level}(message=''); Convex.#{level}(log_preamble.to_s << ': ' << message.to_s); end"
    end
    def log_newline; Convex.log_newline; end
  end
end