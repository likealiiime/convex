begin
  require 'jeweler'
  require './lib/version.rb'
  
  Jeweler::Tasks.new do |gemspec|
    gemspec.version = Convex::Version::STRING
    gemspec.name = "convex"
    gemspec.summary = "CONVersation EXtractor"
    gemspec.description = "Convex is a semantic conversation extractor. It uses the OpenCalais service to understand documents and generate a flurry of information which is stored and manipulated in novel ways by Convex and its lenses."
    gemspec.email = "dev@styledon.com"
    #gemspec.homepage = "http://github.com/StyledOn/convex"
    gemspec.authors = ["Sherród Faulks"]
    gemspec.require_paths = ["lib"]
    %w(ruby-debug redis nokogiri eventmachine SystemTimer json httparty postmark tmail sinatra erubis sinatra-reloader).each do |dependency|
      gemspec.add_dependency dependency
    end
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end

# These are shim tasks because AppCloud tries to run them despite this being
# a Rack/Sinatra app
namespace :db do; task :migrate do; end; end