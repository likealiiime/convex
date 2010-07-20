require 'digest/sha1'

module Convex
  class Datum
    include Convex::CustomizedLogging
    
    ATTRIBUTES = [:value, :created_at, :calais_ref_uri, :styledon_ref_path, :type, :weight, :id, :metadata]
    MUTABLE_ATTRIBUTES = [:weight, :creator_id, :styledon_ref_path] # metadata is mutable, but handled specially
    attr_reader   *(ATTRIBUTES - MUTABLE_ATTRIBUTES)
    attr_accessor *MUTABLE_ATTRIBUTES

    def initialize(configuration)
      configuration.symbolize_keys!
      configuration.delete(:id) if configuration[:id] == 0 || configuration[:id] == '0'
      configuration = {
        :id => Convex.nid,
        :created_at => Time.now,
        :weight => 0.0,
        :type => DatumType::NoType
      }.merge(configuration)
      ATTRIBUTES.each { |attribute|
        instance_variable_set("@#{attribute}".to_sym, configuration[attribute])
      }
    end
  
    def inspect
      "(#{value}/#{type}/#{weight}#{'  #'+id.to_s if id})"
    end
    alias_method :to_s, :inspect
    alias_method :log_preamble, :inspect
    
    def metadata=(new_metadata)
      @metadata = new_metadata.to_s
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
      }.to_json(*args)
    end
    
    def self.json_create(object)
      return self.new(object['attributes'])
    end
  end
end