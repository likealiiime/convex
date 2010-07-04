require 'redis'

RedisDo = Redis.new
RedisDo.setnx '_lachesis', 0
class Redis
  def nid
    RedisDo.incr '_lachesis'
  end
  def cid
    RedisDo.get '_lachesis'
  end
  def cidi
    RedisDo.get('_lachesis').to_i
  end
end

names = <<REDIS
lens-type-id->attribute

chaos-datum->sdfdf0sdfsdofim value
phanes-datum->asdofmsodifmsd value
chronos-datum->asdfasdfsolmd value
REDIS