require 'rubygems'
require 'redis'
require 'nokogiri'
require 'ruby-debug'
require 'pp'

require 'logging'
require 'extensions'
require 'engine'
require 'datum_type'
require 'datum'
   
module Convex
  extend Convex::Logging
  
  @@next_engine_code = nil
  def self.env; @@env; end
  def self.db; @@db; end
  
  def self.boot!(mode = :development)
    @@env = Convex::Environment.new(mode)
    
    Convex.info "Starting Convex in #{env.mode.to_s.upcase} mode..."
    @@db = Redis.new
    debug "Connected to Redis"
    @@db.select env.code
    debug "SELECTed #{env.mode} database, code #{env.code}"
    @@db.setnx '_lachesis', 0
    if env.forgetful?
      warn "Performing FLUSHDB"
      @@db.flushdb
    end
    
    debug "Booting..."
    Convex::DatumType.load!
    info "Loaded DatumTypes"
    log_newline
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
end

module Convex
  class Environment
    attr_accessor :mode
    def initialize(mode)
      @mode = mode.to_sym
    end
    def code
      [:development, :forgetful].index(mode)
    end
    def development?; mode == :development || mode == :forgetful; end
    def forgetful?; mode == :forgetful; end
  end
end

names = <<REDIS
lens-type->id attribute

chaos-datum->sdfdf0sdfsdofim value
phanes-datum->asdofmsodifmsd value
chronos-datum->asdfasdfsolmd value
REDIS