require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'convex') if not defined? Convex
require File.join(Convex::LENSES_PATH, 'chronos', 'chronos') if not defined? Convex::Chronos
require File.join(Convex::LIB_PATH, 'em-websocket', 'em-websocket')

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

Convex.boot! :development

chronos_thread = Thread.new {
  Convex.db.subscribe(:chronos) do |on|
    on.subscribe do |klass, num_subs|
      Convex::Chronos::Service.info "[SUB] Subscribed to #{klass} (now #{num_subs} subscriptions)"
    end
    on.message do |klass, msg|
      Convex::Chronos::Service.info "[SUB] #{klass} forwarded #{'.1fK' % (msg.length / 1024)} message to WebSocket."
      Convex::Chronos::Service.debug "[SUB] Message:\n#{msg}\n--- End of Message\n"
      Thread.current[:websockets] ||= []
      Thread.current[:websockets].each do |ws|
        if ws && ws.state == :connected
          ws.send(msg)
        else
          Thread.current[:websockets].delete(ws)
        end
      end 
    end
    on.unsubscribe do |klass, num_subs|
      Convex::Chronos::Service.info "[SUB] Unsubscribed from #{klass} (now has #{num_subs} subscriptions)"
      Thread.current.kill
    end
  end
}

websocket_thread = Thread.new {
  EventMachine::run do
    trap("INT") {
      Convex.db.unsubscribe :chronos
      EventMachine.stop
      Thread.current.kill
    }

    Convex::Chronos::Service.info "[EM] Now listening for incoming WebSocket connections on #{Convex::SERVICE_ADDRESS}:#{Convex::Chronos::Service::PORT}"
    EventMachine::WebSocket.start(:host => Convex::SERVICE_ADDRESS, :port => Convex::Chronos::Service::PORT) do |ws|
      ws.onopen {
        Convex::Chronos::Service.debug "[EM] WebSocket connection open. Notified client of connection."
        ws.send "connected"
      }
      ws.onclose {
        Convex::Chronos::Service.debug "[EM] WebSocket connection closed."
      }
      ws.onmessage { |msg|
        debug "[EM] Recieved message: #{msg}"
      }
      
      chronos_thread[:websockets] ||= []
      chronos_thread[:websockets] << ws
    end # WebSocket
  end # EventMachine 
}

  chronos_thread.join
websocket_thread.join