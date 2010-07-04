module Convex
  class DatumType
    @@types = {}
    attr_reader :name, :uri
  
    def initialize(name, uri);
      @name, @uri = name, uri;
      constantize!
    end
    def to_s; name; end
    def inspect; "#{name}->#{uri}"; end
  
    def ==(type);
      DatumType === type && type.name == name
    end
  
    # Class Methods
  
    def self.redis_prefix; '_datum_type->'; end
    def self.redis_set_prefix; '_datum_types_set'; end
  
    def self.[](name)
      name = name.to_s
      if self.knows?(name)
        DatumType.new(name, Convex.db.get("#{redis_prefix}#{name}"))
      else
        nil
      end
    end
  
    def self.knows?(name)
      Convex.db.exists "#{redis_prefix}#{name.to_s}"
    end
  
    def self.remember(name, uri='')
      name, uri = name.to_s, uri.to_s
      unless self.knows?(name)
        Convex.db.sadd "#{redis_set_prefix}", name
        Convex.db.setnx "#{redis_prefix}#{name}", uri
        Convex.debug "#{name}->#{uri} Remembered and constantized!"
      end
      return DatumType[name]
    end
  
    def self.load!
      Convex.db.smembers(redis_set_prefix).each do |name|
        DatumType[name]
      end
    
      remember 'NoType'
      remember 'URLDomain'
    end
  
    private
  
    def constantize!
      self.class.const_set(name, self) if not self.class.const_defined?(name)
    end
  end
end