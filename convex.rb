require 'rubygems'
require 'redis'
require 'nokogiri'
require 'ruby-debug'
require 'pp'

require 'extensions'

require 'engine'
require 'datum_type'
require 'datum'
   
module Convex
  @@next_engine_code = nil
  def self.env; @@env; end
  def self.db; @@db; end
  
  def self.boot!(stage = :development)
    @@env = Convex::Environment.new(stage)
    @@filters = []
    @@db = Redis.new
    debug "Connected to Redis"
    @@db.select env.code
    debug "Selected #{env.stage} environment, code #{env.code}"
    @@db.setnx '_lachesis', 0
    if env.testing?
      debug "Performing FLUSHDB"
      @@db.flushdb
    end
    
    debug "Booting..."
    DatumType.load!
    debug "Loaded DatumTypes"
  end
  
  def self.next_engine_code
    @@next_engine_code = @@next_engine_code.nil? ? 'A' : @@next_engine_code.succ
  end
  
  def self.debug(message)
    puts "--- " << message.to_s if env.development?
  end
  
  def self.nid
    Convex.db.incr '_lachesis'
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
    attr_accessor :stage
    def initialize(stage)
      @stage = stage.to_sym
    end
    def code
      [:development, :testing].index(stage)
    end
    def development?; stage == :development || stage == :testing; end
    def testing?; stage == :testing; end
  end
end

names = <<REDIS
lens-type->id attribute

chaos-datum->sdfdf0sdfsdofim value
phanes-datum->asdofmsodifmsd value
chronos-datum->asdfasdfsolmd value
REDIS