module Convex
  module Service
    ADDRESS = '0.0.0.0'
    ACCEPTABLE_ADDRESSES = %w(127.0.0.1)
  end
  
  module RedisService
    PORT = 6379
  end
  
  module ConvexFocusingService
    PORT = 2689 # = CNVX
  end
  
  module Chronos; module Service
    PORT = 8463 # = TIME
  end; end
  
  module Eros; module Service
    PORT = 5683 # = LOVE
  end; end
end