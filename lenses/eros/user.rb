module Convex
  module Eros
    class User
      include Convex::CustomizedLogging

      attr_reader :id, :topics, :ratings
  
      def initialize(id)
        @id = id
        @topics = redis_topics
        ratings!
      end

      def self.redis_key_for(id); Convex::Eros::Lens.redis_key_for_user_set(id); end
      def redis_key; self.class.redis_key_for(self.id); end
      def redis_topics_key; Convex::Eros::Lens.redis_key_for_user_topics(id); end
      
      # Calculating the tanimoto (T) gives us Player's rating of Opponent, 0 ≤ T ≤ 1
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
      
      # Calculating the pearson uses the tanimoto and gives us Player's Similarity to Opponent, -1 ≤ P ≤ 1
      def pearson_against(opp)
        start = Time.now
        user_ids = Convex::Eros::Lens.all_user_ids.collect
        n = user_ids.count
        
        my_sum = user_ids.collect { |id| self.ratings[id].to_f }.sum
        opp_sum = user_ids.collect { |id| opp.ratings[id].to_f }.sum
        my_sumsqr = user_ids.collect { |id| self.ratings[id].to_f ** 2 }.sum
        opp_sumsqr = user_ids.collect { |id| opp.ratings[id].to_f ** 2 }.sum
        our_sumproducts = user_ids.collect { |id| self.ratings[id].to_f * opp.ratings[id].to_f }.sum
        
        a = our_sumproducts - (my_sum * opp_sum / n)
        b = Math.sqrt(
          (my_sumsqr - ((my_sum ** 2) / n)) *
          (opp_sumsqr - ((opp_sum ** 2) / n))
        )
        score = b == 0 ? b : a / b
        debug ("P(%s, %s) = %.4f in %.3f seconds" % [self, opp, score, (Time.now - start)])
        return score
      end
      
      def redis_ratings
        key = Convex::Eros::Lens.redis_key_for_user_ratings(self.id)
        ids = Convex.db.zrange(key, 0, Convex.db.zcard(key))
        Hash[ids.zip(ids.collect { |i| Convex.db.zscore(key, i).to_f })]
      end
      def ratings!; @ratings = redis_ratings; end
      
      def redis_topics; Convex.db.smembers Convex::Eros::Lens.redis_key_for_user_topics(id); end
      def count; topics.count end
      
      def to_s; "##{self.id}/#{self.count}"; end
      
    end
  end
end