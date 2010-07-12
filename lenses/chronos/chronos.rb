module Convex
  module Chronos
    class Lens
      extend Convex::CustomizedLogging
      
      PERIODS = [:life, :hourly, :daily, :weekly, :monthly, :yearly, :death]
      
      def self.is_valid_period?(time); PERIODS.include?(time.to_sym); end
      def self.log_preamble; 'Chronos::Lens'; end
      def self.redis_key_for_list(time); "lens-chronos-#{time.to_s}_index"; end

      def self.focus_using_data!(data, engine)
        log_newline
        hourly_key = redis_key_for_list(:hourly)
        life_key = redis_key_for_list(:life)
        num_clients = 0
        data.each do |datum|
          datum.created_at = Time.now if datum.created_at.nil?
          json = JSON.generate(datum)
          engine.db.zadd  life_key, datum.created_at.to_f, json
          engine.db.lpush hourly_key, json
          num_clients = engine.db.publish :chronos, json
          #debug "[HOURLY] LPUSHed #{datum.hash}"
        end
        debug "[HOURLY] PUBLISHed to #{num_clients} clients"
        info "[HOURLY] LPUSHed #{data.count} data"
        return self
      end
      
      def self.[](period)
        debug "Someone is asking for #{period} data..."
        Convex::Chronos::Lens.validate_period!(period)
        key = Convex::Chronos::Lens.redis_key_for_list(period)
        data = []
        length = Convex.db.llen(key)
        length.times do |i|
          # There's no way to avoid O(N)
          data << JSON.parse(Convex.db.lindex(key, i))
          #debug "#{i}: #{Datum[Convex.db.lindex(key,i)]}"
        end
        debug "Returned #{data.length} data"
        return data
      end
      
      def self.move_data(src, dest)
        validate_period!(src) and validate_period!(dest)
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