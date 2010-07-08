require 'lib/convex'
require 'eventmachine'
require 'lenses/chronos'

module Convex
  module ConvexService
    extend Convex::CustomizedLogging
    CLEARED_ADDRESSES = ['127.0.0.1']
    
    def self.log_preamble; "ConvexService"; end
    
    def post_init
      Convex::ConvexService.info "Accepted connection"
    end
      
    def receive_data(json)
      Convex::ConvexService.info("Received %.1fKB of data" % (json.size / 1024.0))
      transport = JSON.parse(json)
      data = Convex::Engine.new.focus! transport['document'].to_s
      send_data JSON.generate(data)
      close_connection_after_writing
    end
    
    def unbind
      Convex::ConvexService.info "Closed connection"
    end
  end
end

EventMachine::run do
  Convex.boot! :forgetful
  Convex << Convex::Lenses::ChronosLens
  Convex.info "Now listening for incoming connections on 127.0.0.1:2689..."
  EventMachine::start_server '127.0.0.1', 2689, Convex::ConvexService #2689 = CNVX
end