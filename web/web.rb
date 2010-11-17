require 'sinatra/base'
require 'erubis'
require 'sinatra/reloader'

module Convex
  class Web < Sinatra::Base
    set :root, File.dirname(__FILE__)
    
    configure :development do
      register Sinatra::Reloader
      require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'convex'))
      require 'ruby-debug'
      Convex::RedisCommand.conf = File.expand_path(File.join(File.dirname(__FILE__), '..', 'redis.conf'))
    end
    configure :production do
      require 'convex'
      Convex::RedisCommand.conf = '/etc/redis/redis.conf'
    end
    configure do
      Convex.headless!
    end
    
    helpers do
      def class_for_service_running(service)
        @services.select { |svc| svc[:name] == service }.first[:running] ? 'running' : 'notRunning'
      end
    end
    
    get '/convex' do
      @services = [
        {
          :name => :Convex,
          :address => "#{Convex::Service::ADDRESS}:#{Convex::ConvexFocusingService::PORT}",
          :running => Convex::ConvexCommand.running?
        },{
          :name => :Chronos,
          :address => "#{Convex::Service::ADDRESS}:#{Convex::Chronos::Service::PORT}",
          :running => Convex::ChronosCommand.running?
        },{
          :name => :Redis,
          :address => "#{Convex::Service::ADDRESS}:#{Convex::RedisService::PORT}",
          :running => Convex::RedisCommand.running?
        }
      ]
      erubis :index
    end
    
    post '/service/:name/stop' do |name|
      name = name.to_sym
      result = Convex::Command[name].stop!
    end
  end
end