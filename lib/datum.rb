require 'digest/sha1'

module Convex
  class Datum
    include Convex::CustomizedLogging
    
    ATTRIBUTES = [:value, :created_at, :calais_ref_uri, :type, :weight, :id]
    attr_reader   :type, :value, :created_at, :calais_ref_uri, :id
    attr_accessor :weight

    def initialize(configuration)
      configuration = {
        :id => Convex.nid,
        :created_at => Time.now,
        :weight => 0.0,
        :type => DatumType::NoType
      }.merge(configuration)
      ATTRIBUTES.each { |attribute|
        instance_variable_set("@#{attribute}".to_sym, configuration[attribute.to_sym])
      }
    end
  
    def inspect
      "(#{value}/#{type}/#{weight} #{' #'+id.to_s if id})"
    end
    alias_method :to_s, :inspect
    alias_method :log_preamble, :inspect
    
    def self.for_hash(hash)
      key = "datum->#{hash}"
      return Datum.new({
        :value => Convex.db.hget(key, :value),
        :type => Convex.db.hget(key, :type),
        :calais_ref_uri => Convex.db.hget(key, :calais_ref_uri)
      })
    end
    
    def attributes
      attrs = {}
      ATTRIBUTES.each { |a| attrs[a] = self.send(a.to_sym) }
      return attrs
    end
    
    def to_json(*args)
      {
        'json_class' => self.class.name,
        'attributes' => attributes
      }.to_json
    end
    
    def self.json_create(object)
      return self.new(object['attributes'])
    end
  end
end