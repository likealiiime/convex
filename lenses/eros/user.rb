module Convex
  module Eros
    class User
      include Convex::CustomizedLogging

      attr_reader :topics, :id
  
      def initialize(id)
        @id = id
        @topics = redis_topics
      end

      def self.redis_key_for(id); Convex::Eros::Lens.redis_key_for_user_set(id); end
      def redis_key; self.class.redis_key_for(self.id); end
      def redis_topics_key; Convex::Eros::Lens.redis_key_for_user_topics(id); end
      
      def tanimoto_against(opp)
        #puts "Player (##{self.id}) has #{self.topics.count} topics"
        #puts "Opponent (##{opp.id}) has #{opp.topics.count} topics"
        
        start = Time.now
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
        debug("T(%s, %s) = %.4f in %.3f seconds" % [self, opp, score, (Time.now - start)])
        return score
      end
      
      def redis_topics; Convex.db.smembers Convex::Eros::Lens.redis_key_for_user_topics(id); end
      def count; topics.count end
      
      def to_s; "##{self.id}/#{self.count}"; end
      
    end
  end
end