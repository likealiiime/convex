require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'convex') if not defined? Convex
require File.join(File.dirname(__FILE__), 'lens') if not defined? Convex::Chronos
require File.join(Convex::LIB_PATH, 'em-websocket', 'em-websocket')

module Convex
  module Chronos
    module Service
      extend Convex::CustomizedLogging
    end
  end
end

Convex.boot!

chronos_thread = Thread.new {
  Convex::Chronos::Service.debug "[SUB] Subscribing to Redis' chronos channel..."
  Convex.db.subscribe(:chronos) do |on|
    Thread.current[:subscribed] = true
    on.subscribe do |klass, num_subs|
      Convex::Chronos::Service.info "[SUB] Subscribed to #{klass} (now #{num_subs} subscriptions)\n"
    end
    on.message do |klass, msg|
      Thread.current[:websockets] ||= []
      Convex::Chronos::Service.info("[SUB] #{klass} forwarding %.1fK message to #{Thread.current[:websockets].length} WebSocket(s)" % (msg.length / 1024.0))
      Convex::Chronos::Service.debug "[SUB] Message:\n#{msg}\n--- End of Message\n\n"
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
  raise RuntimeError.new("Thread is not subscribed to Redis") unless chronos_thread[:subscribed]
  EventMachine::run do
    trap("INT") {
      Convex.db.unsubscribe :chronos
      EventMachine.stop
      Thread.current.kill
    }

    Convex::Chronos::Service.info "[EM] Now listening for incoming WebSocket connections on #{Convex::Service::ADDRESS}:#{Convex::Chronos::Service::PORT}"
    EventMachine::WebSocket.start(:host => Convex::Service::ADDRESS, :port => Convex::Chronos::Service::PORT) do |ws|
      ws.onopen {
        Convex::Chronos::Service.debug "[EM] WebSocket connection opened"
      }
      ws.onclose {
        Convex::Chronos::Service.debug "[EM] WebSocket connection closed"
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