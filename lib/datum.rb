require 'digest/sha1'

module Convex
  class Datum
    include Convex::CustomizedLogging
    
    ATTRIBUTES = [:value, :created_at, :creator_id, :calais_ref_uri, :type, :weight, :id, :metadata, :source_url]
    attr_reader   *ATTRIBUTES
    attr_accessor :weight, :creator_id
    # Note: creator_id is who generated the Datum, not who created the resource the Datum
    # represents. It is used in Eros to index users' content
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
    
    def topic
      "#{value} (#{type.name})"
    end
    
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
    
    def has_id_and_creator?
      self.creator_id.to_i != 0 && self.id.to_i != 0
    end
  end
end