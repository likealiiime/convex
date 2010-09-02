#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'convex')
require File.join(File.dirname(__FILE__), 'lens')

Convex.boot!
ARGV.shift

Array.class_eval <<END
  def sum; self.reduce(:+); end
  def **(b)
    raise ArgumentError.new("Cannot dot-multiply arrays of differing lengths") if self.length != b.length
    (0...self.length).to_a.collect { |i| self[i] * b[i] }.sum
  end
  def magnitude
    Math.sqrt(self ** self)
  end
  def square_magnitude
    self ** self
  end
END

module Convex
  module Eros
    class User
      attr_reader :data_json, :topics, :id
  
      def initialize(id)
        @id = id
        cache_data!
      end
  
      def cache_data!
        @topics, @data_json = [], []
        Convex.db.smembers(self.key).each do |datum_id|
          json = Convex.db.hget 'lens-chronos-id_index', datum_id
          datum = JSON.parse(json)
          @data_json << json
          @topics << datum.topic
        end
      end
      
      def key; Convex::Eros::Lens.redis_key_for_user_set(self.id); end
      
      def tanimoto_against(opp)
        topic_union = self.topics | opp.topics
        n = topic_union.length
        #puts "N = #{n}"
        #p topic_union
        #puts
        
        a, b = [], []
        n.times do |i|
          topic = topic_union[i]
          a[i] = self.topics.count(topic)
          b[i] = opp.topics.count(topic)
        end
        #puts "A vs B"
        #p a
        #p b
        #puts
        
        #puts "A ** B = %.1f" % a ** b
        #puts "||A||^2 = %.1f" % a.square_magnitude
        #puts "||B||^2 = %.1f" % b.square_magnitude
        score = (a ** b).to_f / (a.square_magnitude + b.square_magnitude - a ** b).to_f
        #puts "T(A,B) = %.4f" % score
        return score
      end
      
      def count; @data_json.count; end
      
    end
  end
end

ply = Convex::Eros::User.new(ARGV.shift)
opp = Convex::Eros::User.new(ARGV.shift)
score = ply.tanimoto_against opp
puts "%.4f" % score