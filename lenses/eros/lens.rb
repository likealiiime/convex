module Convex
  module Eros
    module Lens
      extend Convex::CustomizedLogging
      def self.log_preamble; "Convex::Eros::Lens"; end
      
      def self.redis_key_for_user_set(id); "lens-eros-#{id}"; end
      
      def self.redis_key_for_user_topics(id); "lens-eros-#{id}_topics"; end # List
      def self.redis_key_for_user_test_index(id); "lens-eros-#{id}_test_index"; end # Hash
      def self.redis_key_for_user_test_rank(id); "lens-eros-#{id}_test_rank"; end # ZSet
      
      def self.focus_using_data!(data, engine)
        log_newline
        count = 0
        index = {}
        data.each do |datum|
          next unless datum.has_id_and_creator?
          user_id = datum.creator_id.to_i
          engine.db.sadd redis_key_for_user_set(user_id), datum.id
          store_topic_for_datum datum
          index[user_id] ||= 0
          index[user_id] += 1
          debug "[#{user_id}] SADDed #{datum}"
          count += 1
        end
        info "SADDed #{count}/#{data.length} data to #{index.length} user(s): " << index.collect { |u,n| "  ##{u} got #{n}"}.join(", ") << "\n\n"
        return self
      end
      
      def self.regenerate_all_topics!
        action_start, topics_count = Time.now, 0
        ids = all_user_ids
        ids.each do |user_id|
          Convex.db.del redis_key_for_user_topics(user_id)
          i, start = 0, Time.now
          Convex.db.smembers(redis_key_for_user_set(user_id)).each do |datum_id|
            json = Convex.db.hget 'lens-chronos-id_index', datum_id
            datum = JSON.parse(json)
            store_topic_for_datum(datum)
            i += 1
          end
          topics_count += i
          debug("Generated %d topics for #%d in %.3f seconds" % [i, user_id, (Time.now - start)])
        end
        minutes = (Time.now - action_start) / 60.0
        info("Generated %d topics for %d users in %.1f minutes" % [topics_count, ids.count, minutes])
      end
      
      def self.store_topic_for_datum(datum)
        return unless datum.has_id_and_creator?
        Convex.db.sadd redis_key_for_user_topics(datum.creator_id), datum.topic
        debug "Stored topic #{datum.topic} from #{datum} for ##{datum.creator_id}"
      end
      
      def self.all_user_ids
        pattern = /^lens-eros-(\d+?)$/
        Convex.db.keys('lens-eros-*').collect { |key| key =~ pattern; $1 }.compact
      end
      
      def self.index_tests_for_id(my_id)
        start = Time.now
        me = Convex::Eros::User.new(my_id)
        users = { my_id => me }
        ids = self.all_user_ids
        info "Testing #{ids.count} users against #{me}..."
        ids.each do |opp_id|
          begin
            opponent = users[opp_id] ||= Convex::Eros::User.new(opp_id)
            test_player_against_opponent_and_store! me, opponent
          rescue
            warn "Could not index ##{opp_id} because: #{$!}"
          end
        end
        minutes = (Time.now - start) / 60.0
        info("Indexed %d tests for %s in %.3f minutes" % [ids.count, me, minutes])
      end
      
      def self.test_player_against_opponent_and_store!(player, opponent)
        score = player.tanimoto_against opponent
        Convex.db.hset redis_key_for_user_test_index(player.id), opponent.id, score
        Convex.db.zadd redis_key_for_user_test_rank(player.id), score, opponent.id
      end
      
      def self.score_for_player_id_against_opponent_id(p, o)
        Convex.db.hget(redis_key_for_user_test_index(p), o).to_f
      end
      
      def self.index_all_tests!
        start = Time.now
        
        ids = all_user_ids
        users = {}
        i = 1
        ids.each do |player_id|
          debug "(#{i}/#{ids.count}) Indexing ##{player_id}..."
          
          begin
            player = users[player_id] ||= Convex::Eros::User.new(player_id)
            ids.each do |opponent_id|
              opponent = users[opponent_id] ||= Convex::Eros::User.new(opponent_id)
              test_player_against_opponent_and_store! player, opponent
            end
            t = (Time.now - start) / 60.0
            debug("%.3f minutes have elapsed\n" % t)
          rescue
            warn "Could not index ##{opp_id} because: #{$!}"
          end
          i += 1
        end
        
        minutes = (Time.now - start) / 60.0
        info("Performed %d comparisons in %.3f minutes" % [ids.count ** 2, minutes])
      end
      
      def self.best_n_ids_and_scores_for_id(n, my_id, should_integerize_ids=false)
        key = redis_key_for_user_test_rank(my_id)
        Convex.db.zrevrange(key, 0, n).collect { |match_id|
          next if match_id == my_id
          cast = should_integerize_ids ? :to_i : :to_s
          [match_id.send(cast), Convex.db.zscore(key, match_id).to_f]
        }.compact
      end

      def self.n_ids_and_counts_with_most_data(n, exclude_ids=[])
        exclude_ids.collect!(&:to_s)
        all_user_ids.collect { |id|
          next if exclude_ids.include? id
          [id, Convex.db.scard(redis_key_for_user_set(id))]
        }.compact.sort { |a,b| b.last <=> a.last }[0...n]
      end
      
    end
  end
end

require File.join(File.dirname(__FILE__), 'user')