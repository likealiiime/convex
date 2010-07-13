require File.join(File.dirname(__FILE__), 'lib', 'convex')
require File.join(Convex::LENSES_PATH, 'chronos', 'chronos')

module Convex
  module ConvexFocusingService
    extend Convex::CustomizedLogging
    PORT = 3627 # = FOCS
    
    def self.log_preamble; "ConvexFocusingService"; end
    
    def post_init
      Convex::ConvexFocusingService.info "Accepted connection"
    end
      
    def receive_data(json)
      close_connection
      Convex::ConvexFocusingService.info("Received %.1fKB of data" % (json.size / 1024.0))
      transport = JSON.parse(json)
      Convex::Engine.new.focus! transport['document'].to_s, transport['data']
    end
    
    def unbind
      Convex::ConvexFocusingService.info "Closed connection"
    end
  end
end

EventMachine::run do
  Convex.boot! :development
  Convex << Convex::Chronos::Lens
  Convex::ConvexFocusingService.info "Now listening for incoming connections on #{Convex::SERVICE_ADDRESS}:#{Convex::ConvexFocusingService::PORT}"
  EventMachine::start_server Convex::SERVICE_ADDRESS, Convex::ConvexFocusingService::PORT, Convex::ConvexFocusingService
end