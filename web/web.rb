require 'sinatra/base'
require 'erubis'
require 'sinatra/reloader'

module Convex
  class Web < Sinatra::Base
    set :root, File.dirname(__FILE__)
    
    configure :development do
      register Sinatra::Reloader
      require File.join(File.dirname(__FILE__), '..', 'lib', 'convex')
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
  end
end