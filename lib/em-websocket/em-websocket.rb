require "eventmachine" if not defined? EventMachine

%w[ debugger websocket connection handler_factory handler handler75 handler76 ].each do |file|
  require File.join(File.dirname(__FILE__), 'em-websocket', file)
end
