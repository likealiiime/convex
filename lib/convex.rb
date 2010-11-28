# 3rd-party gems
require 'rubygems'
require 'ruby-debug'
require 'pp'
require 'redis'
require 'nokogiri'
require 'eventmachine'
require 'system_timer'
require 'fileutils'
require 'json/ext' # This is the C version; much faster!

# Convex libraries
%w(version extensions environment logging calais_service engine datum_type datum service_ports command).each do |lib|
  require File.join(File.dirname(__FILE__), lib)
end

module Convex
  extend Convex::Logging
  
  @@db = NilEcho
  @@booted = false
  @@next_engine_code = nil
  
  ROOT_PATH   = File.expand_path(File.join(File.dirname(__FILE__), '..')).freeze
  LIB_PATH    = File.expand_path(File.join(Convex::ROOT_PATH, 'lib')).freeze
  LENSES_PATH = File.expand_path(File.join(Convex::ROOT_PATH, 'lenses')).freeze
  
  def self.env; @@env; end
  def self.db; @@db; end
  def self.booted?; @@booted; end
  
  def self.boot!
    return if booted?
    mode = ARGV.empty? ? :forgetful : ARGV.first.to_sym
  
    raise Environment::CannotBootIntoHeadlessModeError.new("Cannot Convex.boot! into headless mode. Call Convex.headless! instead.") if mode == :headless
    @@env = Convex::Environment.new(mode)
    @@lenses = []
  
    start = Time.now
    Convex.info "Starting Convex in #{env.to_s.upcase} mode..."
    @@db = new_redis_connection
    debug "Connected to Redis"
    @@db.select env.code
    debug "SELECTed #{env} database, code #{env.code}"
    @@db.setnx '_lachesis', 0
    if env.forgetful?
      warn "Performing FLUSHDB"
      @@db.flushdb
    end

    debug "Booting..."
    Convex::DatumType.load!
    @@booted = true
    Convex.info("Started Convex in %.3f seconds" % (Time.now - start))
    
    ARGV.shift
  end
  
  def self.headless!
    return if booted?
    start = Time.now
    Convex.info "Starting Convex in HEADLESS mode..."
    @@env = Convex::Environment.new(:headless)
    debug "Booting..."
    Convex::DatumType.load!
    @@booted = true
    Convex.info("Started Convex in %.3f seconds" % (Time.now - start))
  end
  
  def self.next_engine_code
    @@next_engine_code = @@next_engine_code.nil? ? 'A' : @@next_engine_code.succ
  end
  
  def self.nid
    Convex.db.incr('_lachesis').to_i
  end
  def self.cid
    Convex.db.get '_lachesis'
  end
  def self.cidi
    Convex.db.get('_lachesis').to_i
  end
  
  def self.new_redis_connection
    Redis.new(:host => Convex::Service::ADDRESS, :port => Convex::RedisService::PORT, :timeout => 0)
  end
end

CONVEX_ROOT = Convex::ROOT_PATH