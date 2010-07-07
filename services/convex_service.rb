require 'lib/convex'
require 'eventmachine'
require 'lenses/chronos'

module Convex
  module ConvexService
    extend Convex::CustomizedLogging
    
    def self.log_preamble; "ConvexService"; end
    
    def post_init
      Convex::ConvexService.info "Accepted connection"
    end
      
    def receive_data(data)
      Convex::Engine.new.focus! data
      close_connection
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