require File.join(File.dirname(__FILE__), 'convex')
require File.join(Convex::LENSES_PATH, 'chronos', 'lens')
require File.join(Convex::LENSES_PATH, 'eros', 'lens')

module Convex
  module ConvexFocusingService
    extend Convex::CustomizedLogging
    
    def self.log_preamble; "ConvexFocusingService"; end
    
    def post_init
      Convex::ConvexFocusingService.info "Accepted connection"
    end
      
    def receive_data(json)
      close_connection
      Convex::ConvexFocusingService.info("Received %.1fKB of data" % (json.size / 1024.0))
      begin
        transport = JSON.parse(json)
        Convex::Engine.new.focus! transport['document'].to_s, transport['data'], transport['overrides']
      rescue
        Convex::ConvexFocusingService.error("#{$!.class}: #{$!}\n" << $!.backtrace.join("\n") << "\n\n")
      end
    end
    
    def unbind
      Convex::ConvexFocusingService.info "Closed connection"
    end
  end
end

EventMachine::run do
  Convex.boot!
  Convex << [Convex::Chronos::Lens, Convex::Eros::Lens]
  Convex::ConvexFocusingService.info "Now listening for incoming connections on #{Convex::Service::ADDRESS}:#{Convex::ConvexFocusingService::PORT}"
  EventMachine::start_server Convex::Service::ADDRESS, Convex::ConvexFocusingService::PORT, Convex::ConvexFocusingService
end