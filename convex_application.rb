require 'rubygems'
require 'redis'
require 'nokogiri'
require 'ruby-debug'
require 'pp'

require 'extensions'
require 'datum_type'
require 'datum'

class ConvexApplication
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
  
  attr_reader :db, :env
  
  def initialize(stage)
    @env = Environment.new(stage)
    @db = Redis.new
    db.select env.code
    db.setnx '_lachesis', 0
  end
  
  def boot!
    DatumType.load!
  end
  
  def debug(*message)
    puts *message if env.development?
  end
  
  def nid
    db.incr '_lachesis'
  end
  def cid
    db.get '_lachesis'
  end
  def cidi
    db.get('_lachesis').to_i
  end
end

names = <<REDIS
lens-type-id->attribute

chaos-datum->sdfdf0sdfsdofim value
phanes-datum->asdofmsodifmsd value
chronos-datum->asdfasdfsolmd value
REDIS