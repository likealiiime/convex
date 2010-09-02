module Convex
  module Chronos
    class Lens
      extend Convex::CustomizedLogging
      
      PERIODS = [:life, :hourly, :daily, :weekly, :monthly, :yearly, :death, :id]
      TRANSIENT_PERIODS = PERIODS - [:life, :death, :id]
      
      def self.is_valid_period?(time); PERIODS.include?(time.to_sym); end
      def self.log_preamble; 'Chronos::Lens'; end
      def self.redis_key_for_list(time); "lens-chronos-#{time.to_s}_index"; end

      def self.focus_using_data!(data, engine)
        log_newline
        num_clients = 0
        data.each do |datum|
          datum.created_at = Time.now if datum.created_at.nil?
          json = JSON.generate(datum)
          engine.db.hset  redis_key_for_list(:id), datum.id, json
          engine.db.zadd  redis_key_for_list(:life), datum.created_at.to_f, json
          engine.db.lpush redis_key_for_list(:hourly), json
          num_clients = engine.db.publish :chronos, json
        end
        info "[HOURLY] LPUSHed #{data.count} data"
        debug "[HOURLY] PUBLISHed to #{num_clients} clients"
        return self
      end
      
      def self.index_ids!
        regexp = /"id":(\d+)/
        num_created = 0
        Convex.db.zrevrange(redis_key_for_list(:life), 0,-1).each do |json|
          match = json.match(regexp)
          next unless match
          id = match[1]
          created = Convex.db.hset(redis_key_for_list(:id), id, json)
          debug "Datum ##{id} was #{created ? 'newly indexed' : 'already indexed'}"
          num_created += 1 if created
        end
        info "#{num_created} data were newly indexed"
        return num_created
      end  
      
      def self.id_datum_json(id)
        json = Convex.db.hget(redis_key_for_list(:id), id)
        if json
          debug "Found ##{id}: #{json}"
        else
          warn "Datum ##{id} either does not exist or is not indexed"
        end
        return json
      end
      
      def self.ping
        debug "Someone is pinging the lens..."
        pong = [Convex.db.zcard(redis_key_for_list(:life))]
        pong += TRANSIENT_PERIODS.collect { |p| Convex.db.llen(redis_key_for_list(p)) }
        info  "Pong: #{pong.join(' ')}"
        pong.join(' ')
      end
      
      def self.[](period)
        debug "Someone is asking for #{period} data..."
        Convex::Chronos::Lens.validate_period!(period)
        key = Convex::Chronos::Lens.redis_key_for_list(period)
        data = JSON.parse(Convex.db.lrange(key, 0, Convex.db.llen(key) - 1).join(','))
        debug "Returned #{data.length} data"
        return data
      end
      
      def self.context_json(n)
        debug "Someone is asking for the last #{n} hourly data as context..."
        key = Convex::Chronos::Lens.redis_key_for_list :hourly
        return '[' + (Convex.db.lrange(key, 0, n-1) || []).join(',') + ']'
      end
      
      def self.move_data(src, dest)
        validate_period!(src) and validate_period!(dest)
        raise ArgumentError.new("Cannot move data into or out of ID index") if dest == :id || src == :id
        raise ArgumentError.new("Cannot move data into or out of Life timeline") if dest == :life || src == :life
        raise ArgumentError.new("Cannot move data out of Death timeline") if src == :death
                
        length = Convex.db.llen(redis_key_for_list(src)).to_i
        src_list  = redis_key_for_list src
        dest_list = redis_key_for_list dest
        hashes = []
        length.times do |i|
          hashes << if dest != :death
            Convex.db.rpoplpush(src_list, dest_list)
          else
            # Just RPOPping is fine. No matter what, it's O(N)
            Convex.db.rpop(src_list)
          end
        end
        #debug "Moved: " << hashes.inspect
        info "[#{src.to_s.upcase}->#{dest.to_s.upcase}] Moved #{length} data"
        return hashes
      end
      
      def self.validate_period!(period)
        raise ArgumentError.new("Period must be one of " << PERIOD.collect { |p| ":#{p.to_s}" }.join(', ')) unless is_valid_period?(period.to_sym)
        return true
      end
      
    end
  end
end