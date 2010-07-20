module Convex
  module Eros
    module Lens
      extend Convex::CustomizedLogging
      
      def self.redis_key_for_user_set(id); "lens-eros-#{id}"; end
      
      def self.focus_using_data!(data, engine)
        log_newline
        count = 0
        index = {}
        data.each do |datum|
          next if datum.creator_id.to_i == 0 || datum.id.to_i == 0
          engine.db.sadd redis_key_for_user_set(datum.creator_id), datum.id
          index[datum.creator_id.to_i] ||= 0
          index[datum.creator_id.to_i] += 1
          debug "[#{datum.creator_id}] SADDed #{datum}"
          count += 1
        end
        info "SADDed #{count}/#{data.length} data to #{index.length} user(s): " << index.collect { |u,n| "  ##{u} got #{n}"}.join(", ") << "\n\n"
        return self
      end
      
    end
  end
end