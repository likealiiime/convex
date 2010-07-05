module Convex
  module Logging
    def time_for_log
      Time.now.strftime("%b %d %y %I:%M:%S%p")
    end

    def log_newline
      puts ""
    end
    
    def log(message='')
      puts "[#{time_for_log}] " << message.to_s
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
      log "/!\\ " << message.to_s
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