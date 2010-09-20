require 'sinatra/base'
require 'erubis'
require 'sinatra/reloader'

module Convex
  class Web < Sinatra::Base
    class Service < Struct.new(:name, :command)
      def stop_command
        "#{File.join(Convex::ROOT_PATH, self.command)} stop"
      end
    end
    Services = {
      :Convex => Convex::Web::Service.new(:Convex, 'convexd')
    }
    
    set :root, File.dirname(__FILE__)
    
    configure :development do
      register Sinatra::Reloader
      require File.join(File.dirname(__FILE__), '..', 'lib', 'convex')
      require 'ruby-debug'
    end
    configure :production do
      require 'convex'
    end
    configure do
      Convex.headless!
    end
    
    helpers do
      def class_for_service_running(service)
        @services.select { |svc| svc[:name] == service }.first[:running] ? 'running' : 'notRunning'
      end
    end
    
    get '/' do
      @services = [
        {
          :name => :Convex,
          :address => "#{Convex::Service::ADDRESS}:#{Convex::ConvexFocusingService::PORT}",
          :running => File.exist?(File.join(Convex::PIDS_PATH, 'convexd.pid'))
        },{
          :name => :Chronos,
          :address => "#{Convex::Service::ADDRESS}:#{Convex::Chronos::Service::PORT}",
          :running => File.exist?(File.join(Convex::PIDS_PATH, 'chronosd.pid'))
        },{
          :name => :Redis,
          :address => "#{Convex::Service::ADDRESS}:#{Convex::RedisService::PORT}",
          :running => File.exist?(File.join(Convex::PIDS_PATH, 'redis.pid'))
        }
      ]
      erubis :index
    end
    
    post '/service/:name/stop' do |name|
      name = name.to_sym
      command = Convex::Web::Services[name].stop_command
      puts command
    end
  end
end