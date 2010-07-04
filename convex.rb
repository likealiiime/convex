require 'rubygems'
require 'redis'
require 'nokogiri'
require 'ruby-debug'
require 'pp'

require 'extensions'
require 'datum_type'
require 'datum'

module Convex
  class Environment
    attr_accessor :stage
    def initialize(stage)
      @stage = stage.to_sym
    end
    def code
      case stage.to_s
      when 'development' then 0
      else 1
      end
    end
    def development?; stage == :development; end
  end
end
   
module Convex
  def self.db; @@db; end
  def self.env; @@env; end
  
  def self.boot!(stage = :development)
    @@env = Convex::Environment.new(stage)
    @@db = Redis.new
    debug "Connected to Redis"
    @@db.select env.code
    debug "Selecting #{env.stage} environment, code #{env.code}"
    @@db.setnx '_lachesis', 0
    
    debug "Booting..."
    DatumType.load!
  end
  
  def self.debug(message)
    puts "--- " << message if env.development?
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

names = <<REDIS
lens-type->id attribute

chaos-datum->sdfdf0sdfsdofim value
phanes-datum->asdofmsodifmsd value
chronos-datum->asdfasdfsolmd value
REDIS