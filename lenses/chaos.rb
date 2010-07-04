module Convex
  module Lenses
    class Chaos
      def self.<<(datum)
        return unless Datum === datum
      end
    end
  end
end