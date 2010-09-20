require 'sinatra/base'
require 'erubis'

module Convex
  class Web < Sinatra::Base
    set :root, File.dirname(__FILE__)
    
    get '/' do
      erubis :index
    end
  end
end