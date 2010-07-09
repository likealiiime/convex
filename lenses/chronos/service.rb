require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'convex') if not defined? Convex
require File.join(Convex::LENSES_PATH, 'chronos', 'chronos') if not defined? Convex::Chronos

module Convex
  module Chronos
    module Service
      PORT = 8463 # = TIME
      extend Convex::CustomizedLogging
    
      def self.log_preamble; "Chronos::Service"; end
    
      def post_init
        Convex::Chronos::Service.info "Accepted connection"
      end
      
      def receive_data(period)
        send_data JSON.generate(Convex::Chronos::Lens[period])
        close_connection_after_writing
      end
    
      def unbind
        Convex::Chronos::Service.info "Closed connection"
      end
    end
  end
end

EventMachine::run do
  Convex.boot! :development
  Convex::Chronos::Service.info "Now listening for incoming connections on #{Convex::SERVICE_ADDRESS}:#{Convex::Chronos::Service::PORT}"
  EventMachine::start_server Convex::SERVICE_ADDRESS, Convex::Chronos::Service::PORT, Convex::Chronos::Service
end