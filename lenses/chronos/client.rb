require File.join(File.dirname(__FILE__), 'chronos') if not defined? Convex::Chronos::Lens

module Convex
  module Chronos
    class Client < EventMachine::Connection
      include Convex::CustomizedLogging
      
      def self.log_preamble; 'Convex::Chronos::Client'; end
      def self.request(period)
        EventMachine::run {
          EventMachine::connect Convex::SERVICE_ADDRESS, 8463, Convex::Chronos::Client, period
        }
        return @@data
      end
      
      def initialize(period)
        @period = period
        super
      end
      
      def post_init
        puts "Convex::Chronos::Client is sending data..."
        send_data @period
        puts "...Sent!"
      end

      def receive_data(data)
        puts "Convex::Chronos::Client received data"
        @@data = JSON.parse(data)
        EventMachine::stop_event_loop
      end
      
      def unbind
        puts "Convex::Chronos::Client is done!"
        #raise IOError.new('An unspecified IO error occured in Convex::Chronos::Client') if error?
        EventMachine::stop_event_loop
      end
    end
  end
end