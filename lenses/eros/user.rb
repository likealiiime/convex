module Convex
  module Eros
    class User
      include Convex::CustomizedLogging

      attr_reader :id
  
      def initialize(id); @id = id; end
      
      def topics(n=0); @topics ||= redis_topics(n); end
      def topics!(n=0); @topics = redis_topics(n); end
      
      def ratings; @ratings ||= redis_ratings; end
      def ratings!; @ratings = redis_ratings; end
      
      def word_counts; @word_counts ||= redis_word_counts; end
      def word_counts!; @word_counts = redis_word_counts; end
      
      # Calculating the tanimoto (T) gives us Player's rating of Opponent, 0 ≤ T ≤ 1
      def tanimoto_against(opp)
        #puts "Player (##{self.id}) has #{self.topics.count} topics"
        #puts "Opponent (##{opp.id}) has #{opp.topics.count} topics"
        
        start = Time.now
        topic_union = self.topics(300) | opp.topics(300)
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
      
      def self.pearson(v1, v2, should_subtract=false)
        sum1, sum2 = v1.sumf, v2.sumf
        sumsqr1, sumsqr2 = v1.collect { |x| x ** 2 }.sumf, v2.collect { |x| x ** 2 }.sumf
        sump = []
        v1.each_index { |i| sump << v1[i] * v2[i] }
        sump = sump.sumf
        n = v1.count.to_f
        num = sump - (sum1 * sum2 / n)
        den = Math.sqrt(
          (sumsqr1 - ((sum1 ** 2) / n)) *
          (sumsqr2 - ((sum2 ** 2) / n))
        )
        return 0 if den == 0
        score = num / den
        should_subtract ? 1.0 - score : score
      end
      
      # Calculating the pearson uses the tanimoto and gives us Player's Similarity to Opponent, -1 ≤ P ≤ 1
      def pearson_against(opp)
        start = Time.now
        user_ids = Convex::Eros::Lens.all_user_ids.collect
        n = user_ids.count.to_f
        
        my_sum = user_ids.collect { |id| self.ratings[id].to_f }.sumf
        opp_sum = user_ids.collect { |id| opp.ratings[id].to_f }.sumf
        my_sumsqr = user_ids.collect { |id| self.ratings[id].to_f ** 2 }.sumf
        opp_sumsqr = user_ids.collect { |id| opp.ratings[id].to_f ** 2 }.sumf
        our_sumproducts = user_ids.collect { |id| self.ratings[id].to_f * opp.ratings[id].to_f }.sumf
        
        a = our_sumproducts - (my_sum * opp_sum / n)
        b = Math.sqrt(
          (my_sumsqr - ((my_sum ** 2) / n)) *
          (opp_sumsqr - ((opp_sum ** 2) / n))
        )
        score = b == 0 ? b : a / b
        debug ("P(%s, %s) = %.4f in %.3f seconds" % [self, opp, score, (Time.now - start)])
        return score
      end
      
      def self.kcluster(users, k = 4)
        start = Time.now
        # Find the lowest and highest
        combined_words = users.collect { |u| u.word_counts.keys }.reduce(:|)
        puts "combined_words = #{combined_words.inspect}"
        rows = (0...users.count).collect { [] } # [ [] ... ]
        combined_words.each { |word|
          users.count.times { |i|
            rows[i] << (users[i].word_counts[word] || 0)
          }
        }
        puts "rows = #{rows.inspect}"
        num_words = combined_words.length
        puts "num_words = #{num_words}"
        # The min and max occurences for each word across both of us, like:
        # [[min,max], [min, max], ... ]
        # Each element's index corresponds to that word's index in combined_words
        i = 0
        ranges = combined_words.collect { |words|
          min = (0...users.count).collect { |row| rows[row][i] }.min
          max = (0...users.count).collect { |row| rows[row][i] }.max
          i += 1
          [min, max]
        }
        puts "ranges = #{ranges.inspect}"
        
        zero_to_k = (0...k).to_a
        puts "zero_to_k = #{zero_to_k.inspect}"
        # There are k centroids with num_words length
        centroids = zero_to_k.collect { |n|
          (0...num_words).collect { |i|
            rand * (ranges[i][1] - ranges[i][0]) + ranges[i][0]
          }
        }
        puts "centroids = #{centroids.inspect}"
        
        last_matches, best_matches = nil, nil
        (0...100).each { |t|
          users.first.debug "Iteration #{t}"
          best_matches = zero_to_k.collect { |n| [] }
          
          # Find which centroid is the closest for each row
          users.count.times { |person|
            row = rows[person]
            best_match = 0
            k.times { |n|
              d = Convex::Eros::User.pearson(centroids[n], row, true)
              best_match = n if d < Convex::Eros::User.pearson(centroids[best_match], row, true)
            }
            best_matches[best_match] << person
            
            # If the results are the same as last time, this is complete
            break if best_matches == last_matches
            last_matches = best_matches
          }
          
          k.times { |n|
            averages = [0.0] * num_words
            if best_matches[n].count > 0
              best_matches[n].each { |row_id|
                rows[row_id].count.times { |m|
                  averages[m] += rows[row_id][m]
                }
              }
              averages.count.times { |j|
                averages[j] /= best_matches[n].count
              }
              centroids[n] = averages
            end
          }
        }
        minutes = (Time.now - start) / 60.0
        users.first.info("Took %.1f minutes" % minutes)
        return best_matches
      end
      
      def self.redis_key_for(id); Convex::Eros::Lens.redis_key_for_user_set(id); end
      def redis_key; self.class.redis_key_for(self.id); end
      def redis_topics_key; Convex::Eros::Lens.redis_key_for_user_topics(id); end
      
      def redis_ratings
        key = Convex::Eros::Lens.redis_key_for_user_ratings(self.id)
        ids = Convex.db.zrange(key, 0, Convex.db.zcard(key))
        Hash[ids.zip(ids.collect { |i| Convex.db.zscore(key, i).to_f })]
      end
      
      # This gives us the most recent n topics; all when n is unspecified
      def redis_topics(n=0)
        Convex.db.zrevrange redis_topics_key, 0, n - 1
      end
      
      def redis_word_counts
        key = Convex::Eros::Lens.redis_key_for_user_word_counts(self.id)
        words = Convex.db.zrange(key, 0, Convex.db.zcard(key))
        Hash[words.zip(words.collect { |i| Convex.db.zscore(key, i).to_i })]
      end
      
      def to_s; "##{self.id}"; end
      alias :inspect :to_s
    end
  end
end