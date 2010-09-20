require 'rubygems'
require 'sinatra'
require 'erubis'

get '/' do
  erubis :index
end