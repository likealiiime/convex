module Convex
  module Eros
    module Lens
      extend Convex::CustomizedLogging
      def self.log_preamble; "Convex::Eros::Lens"; end
      
      ### Redis ###
      def self.redis_key_for_user_set(id); "lens-eros-#{id}"; end
      def self.redis_key_for_user_topics(id); "lens-eros-#{id}_topics"; end # Set
      def self.redis_key_for_user_words(id); "lens-eros-#{id}_words"; end # List
      def self.redis_key_for_user_ratings(id); "lens-eros-#{id}_test_rank"; end # ZSet
      def self.redis_key_for_user_similarities(id); "lens-eros-#{id}_similarity_index"; end # ZSet
      
      ### Convex ###
      def self.focus_using_data!(data, engine)
        log_newline
        count = 0
        index = {}
        data.each do |datum|
          next unless datum.has_id_and_creator?
          user_id = datum.creator_id.to_i
          engine.db.sadd(redis_key_for_user_set(user_id), datum.id)
          store_topic_using_datum(datum)
          index[user_id] ||= 0
          index[user_id] += 1
          debug "[#{user_id}] SADDed #{datum}"
          count += 1
        end
        info "SADDed #{count}/#{data.length} data to #{index.length} user(s): " << index.collect { |u,n| "  ##{u} got #{n}"}.join(", ") << "\n\n"
        return self
      end
      
      ### Utility ###
      def self.all_user_ids
        pattern = /^lens-eros-(\d+?)$/
        Convex.db.keys('lens-eros-*').collect { |key| key =~ pattern; $1 }.compact
      end
      
      def self.all_users
        all_user_ids.collect { |id| Convex::Eros::User.new(id) }
      end
      
      def self.all_users_hash
        Hash[all_user_ids.zip(all_users)]
      end
      
      def self.similarity_between(ply_id, opp_id)
        Convex.db.zscore(redis_key_for_user_similarities(ply_id), opp_id).to_f
      end
      
      ### Topics ###
      def self.theme_all!
        start = Time.now
        ids = all_user_ids
        ids.each do |user_id|
          Convex.db.del redis_key_for_user_topics(user_id)
          theme!(user_id)
        end
        minutes = (Time.now - start) / 60.0
        info("Generated topics for %d users in %.1f minutes" % [topics_count, ids.count, minutes])
      end
      
      def self.theme!(my_id)
        start = Time.now
        i = 0
        datum_ids = Convex.db.smembers(redis_key_for_user_set(my_id))
        datum_ids.each do |datum_id|
          json = Convex.db.hget 'lens-chronos-id_index', datum_id
          datum = JSON.parse(json)
          store_topic_using_datum(datum)
          i += 1
        end
        info("Generated %d topics from %d data for #%d in %.1f seconds" % [Convex.db.scard(redis_key_for_user_topics(my_id)), datum_ids.count, my_id, (Time.now - start)])
      end
      
      def self.store_topic_using_datum(datum)
        return unless datum.has_id_and_creator?
        Convex.db.sadd redis_key_for_user_topics(datum.creator_id), datum.topic
        debug "Stored topic #{datum.topic} using for ##{datum.creator_id}"
      end
      
      ### Ratings ###
      def self.rate!(my_id)
        start = Time.now
        me = Convex::Eros::User.new(my_id)
        users = { my_id => me }
        ids = self.all_user_ids
        info "Rating #{ids.count} users against #{me}..."
        ids.each do |opp_id|
          begin
            opponent = users[opp_id] ||= Convex::Eros::User.new(opp_id)
            rate_player_against_opponent_and_store! me, opponent
          rescue
            warn "Could not rate ##{opp_id} because: #{$!}"
          end
        end
        minutes = (Time.now - start) / 60.0
        info("Rated %d users against %s in %.3f minutes" % [ids.count, me, minutes])
      end
      
      def self.rate_all!
        start = Time.now
        ids = all_user_ids
        users = {}
        i = 1
        ids.each do |player_id|
          debug "(#{i}/#{ids.count}) Rating ##{player_id}..."
          begin
            player = users[player_id] ||= Convex::Eros::User.new(player_id)
            ids.each do |opponent_id|
              opponent = users[opponent_id] ||= Convex::Eros::User.new(opponent_id)
              rate_player_against_opponent_and_store!(player, opponent)
            end
            t = (Time.now - start) / 60.0
            debug("%.3f minutes have elapsed\n\n" % t)
          rescue
            warn "Could not rate ##{opp_id} because: #{$!}"
          end
          i += 1
        end
        
        minutes = (Time.now - start) / 60.0
        info("Performed %d ratings in %.3f minutes" % [ids.count ** 2, minutes])
      end
      
      def self.rate_player_against_opponent_and_store!(player, opponent)
        Convex.db.zadd redis_key_for_user_ratings(player.id), player.tanimoto_against(opponent), opponent.id
      end
      
      ### Similarities ###
      def self.evaluate!(my_id)
        start = Time.now
        me = Convex::Eros::User.new(my_id)
        users = { my_id => me }
        ids = all_user_ids
        info "Evaluating #{ids.count} users against #{me}..."
        ids.each do |opp_id|
          begin
            opponent = users[opp_id] ||= Convex::Eros::User.new(opp_id)
            evaluate_player_against_opponent_and_store! me, opponent
          rescue
            warn "Could not evaluate ##{opp_id} because: #{$!}"
          end
        end
        minutes = (Time.now - start) / 60.0
        info("Evaluated %d users against %s in %.3f minutes" % [ids.count, me, minutes])
      end
      
      def self.evaluate_all!
        start = Time.now
        ids = all_user_ids
        users = {}
        i = 1
        ids.each do |player_id|
          debug "(#{i}/#{ids.count}) Evaluating ##{player_id}..."
          begin
            player = users[player_id] ||= Convex::Eros::User.new(player_id)
            ids.each do |opponent_id|
              opponent = users[opponent_id] ||= Convex::Eros::User.new(opponent_id)
              evaluate_player_against_opponent_and_store!(player, opponent)
            end
            t = (Time.now - start) / 60.0
            debug("%.3f minutes have elapsed\n\n" % t)
          rescue
            warn "Could not evaluate ##{opp_id} because: #{$!}"
          end
          i += 1
        end
        
        minutes = (Time.now - start) / 60.0
        info("Performed %d evaluations in %.3f minutes" % [ids.count ** 2, minutes])
      end
      
      def self.evaluate_player_against_opponent_and_store!(player, opponent)
        Convex.db.zadd redis_key_for_user_similarities(player.id), player.pearson_against(opponent), opponent.id
      end
      
      ### Testing ###
      def self.test!(my_id)
        start = Time.now
        users = all_users_hash
        me = users[my_id.to_s]
        info "Testing #{users.count} users against #{me}..."
        users.each do |opp_id, opponent|
          test_player_against_opponent_and_store!(me, opponent) rescue warn("Could not test ##{opp_id} because: #{$!}")
        end
        minutes = (Time.now - start) / 60.0
        info("Tested %d users against %s in %.3f minutes" % [users.count, me, minutes])
      end
      
      def self.test_all!
        start = Time.now
        users = all_users_hash
        i = 1
        users.each do |player|
          debug "(#{i}/#{ids.count}) Indexing ##{player}..."
          begin
            users.each { |opponent| test_player_against_opponent_and_store!(player, opponent) }
            t = (Time.now - start) / 60.0
            debug("%.3f minutes have elapsed\n\n" % t)
          rescue
            warn "Could not index ##{opp_id} because: #{$!}"
          end
          i += 1
        end        
        minutes = (Time.now - start) / 60.0
        info("Performed %d comparisons in %.3f minutes" % [users.count ** 2, minutes])
      end
      
      def self.test_player_against_opponent_and_store!(player, opponent)
        rate_player_against_opponent_and_store!(player, opponent)
        player.ratings!; opponent.ratings!
        evaluate_player_against_opponent_and_store!(player, opponent)
      end
      
      ### Ranking ###
      def self.best_n_ids_and_scores_for_id(n, my_id, options={})
        key = send("redis_key_for_user_#{options[:method] || 'similarities'}".to_sym, my_id)
        cast = options[:integerize_ids] ? :to_i : :to_s
        Convex.db.zrevrange(key, 0, n).collect { |match_id|
          next if match_id == my_id
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