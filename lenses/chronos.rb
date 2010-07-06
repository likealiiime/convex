module Convex
  module Lenses
    class ChronosLens < Convex::Lens
      extend Convex::CustomizedLogging
      
      def self.log_preamble; 'ChronosLens'; end
      def self.redis_key_for_list(time); "lens-chronos-#{time.to_s}_index"; end
      
      def self.focus_using_data!(data, engine)
        # Sadd to hourly
        # Check each for date
        data.each do |datum|
          datum.created_at = Time.now if datum.created_at.nil?
          engine.db.lpush redis_key_for_list(:hourly), datum.hash
          debug "[HOURLY] LPUSHed #{datum.hash}"
        end
        info "[HOURLY] LPUSHed #{data.count} data"
      end
      
      def self.move_data(src, dest)
        length = Convex.db.llen(redis_key_for_list(src)).to_i
        src_list  = redis_key_for_list src
        dest_list = redis_key_for_list dest
        length.times do |i|
          Convex.db.rpoplpush src_list, dest_list
          debug "[#{src.to_s.upcase}] RPOPped"
          debug "[#{dest.to_s.upcase}] LPUSHed"
        end
        info "[#{dest.to_s.upcase}] Received #{length} data from #{src.to_s.upcase}"
      end
    end
  end
end