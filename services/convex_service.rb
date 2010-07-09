require 'lib/convex'
require 'eventmachine'
require 'lenses/chronos'

module Convex
  SERVICE_ADDRESS = '127.0.0.1'
  CLEARED_ADDRESSES = ['127.0.0.1']
  
  module ConvexFocusingService
    extend Convex::CustomizedLogging
    PORT = 3628 # = FOCU
    
    def self.log_preamble; "ConvexFocusingService"; end
    
    def post_init
      Convex::ConvexFocusingService.info "Accepted connection"
    end
      
    def receive_data(json)
      Convex::ConvexFocusingService.info("Received %.1fKB of data" % (json.size / 1024.0))
      transport = JSON.parse(json)
      data = Convex::Engine.new.focus! transport['document'].to_s, transport['data']
      close_connection
    end
    
    def unbind
      Convex::ConvexFocusingService.info "Closed connection"
    end
  end
end

EventMachine::run do
  Convex.boot! :forgetful
  Convex << Convex::Lenses::ChronosLens
  Convex.info "Now listening for incoming connections on 127.0.0.1:2689..."
  EventMachine::start_server Convex::SERVICE_ADDRESS, Convex::ConvexFocusingService::PORT, Convex::ConvexFocusingService
end