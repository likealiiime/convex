module Convex
  class Filter
    attr_reader :block
    
    def initialize(&block)
      @block = block
    end
    def using(nokogiri_doc)
      block.call(nokogiri_doc)
    end
  end
  
  CalaisHeaderFilter = Filter.new do |xml|
    
  end
end

