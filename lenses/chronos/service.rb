require 'rubygems'
require 'convex'
require File.join(File.dirname(__FILE__), 'lens') if not defined? Convex::Chronos::Lens
require File.join(Convex::LIB_PATH, 'em-websocket', 'em-websocket')

module Convex
  module Chronos
    module Service
      extend Convex::CustomizedLogging
    end
  end
end

Convex.boot!
Convex.force_debug_logging!
Thread.abort_on_exception = true

chronos_thread = Thread.new {
  Convex::Chronos::Service.debug "[SUB] Subscribing to Redis' chronos channel..."
  # A subscribed connection cannot do anything other than unsubscribe, so use a new connection
  Convex.new_redis_connection.subscribe(:chronos) do |on|
    
    Thread.current[:subscribed] = true
    
    on.subscribe do |klass, num_subs|
      Convex::Chronos::Service.info "[SUB] Subscribed to #{klass} (now #{num_subs} subscriptions)\n"
      chronos_thread = Thread.current
      
      Thread.current[:web_socket_thread] = Thread.new {
        raise RuntimeError.new("Thread is not subscribed to Redis") unless chronos_thread[:subscribed]
        Convex::Chronos::Service.debug "[EM] Starting reactor..."
        EventMachine::run do
          Convex::Chronos::Service.info "[EM] Now listening for WebSocket connections on #{Convex::Service::ADDRESS}:#{Convex::Chronos::Service::PORT}"
          EventMachine::WebSocket.start(:host => Convex::Service::ADDRESS, :port => Convex::Chronos::Service::PORT, :debug => true) do |ws|
            ws.onopen {
              Convex::Chronos::Service.debug "[WS] WebSocket connection opened"
            }
            ws.onclose {
              Convex::Chronos::Service.debug "[WS] WebSocket connection closed"
            }
            ws.onmessage { |msg|
              Convex::Chronos::Service.debug "[WS] Recieved message: #{msg}"
              if msg[0..6] == 'context'
                n = msg.split(' ').last.to_i
                Convex::Chronos::Service.debug "[WS] Received CONTEXT command. Replying with context of #{n}..."
                ws.send("context-" << Convex::Chronos::Lens.context_json(n))
              end
            }

            chronos_thread[:web_sockets] ||= []
            chronos_thread[:web_sockets] << ws
          end # WebSocket
          
          trap("INT") {
            Convex.db.unsubscribe :chronos
          }
        end # EventMachine 
      } # WebSocket thread
      
    end
    
    on.message do |klass, msg|
      Thread.current[:web_sockets] ||= []
      Convex::Chronos::Service.info("[SUB] #{klass} forwarding %.1fK message to #{Thread.current[:web_sockets].length} WebSocket(s)" % (msg.length / 1024.0))
      Convex::Chronos::Service.debug "[SUB] Message:\nnew-#{msg}\n--- End of Message\n\n"
      Thread.current[:web_sockets].each do |ws|
        if ws && ws.state == :connected
          ws.send("new-" << msg)
        else
          Thread.current[:web_sockets].delete(ws)
        end
      end 
    end
    
    on.unsubscribe do |klass, num_subs|
      Convex::Chronos::Service.info "[SUB] Unsubscribed from #{klass} (now has #{num_subs} subscriptions)"
      Thread.current[:web_socket_thread].kill
      Thread.current.kill
    end
    
  end
}

chronos_thread.join