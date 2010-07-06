require 'digest/sha1'

module Convex
  class Datum
    include Convex::CustomizedLogging
    
    ATTRIBUTES = [:value, :created_at, :calais_ref_uri, :type, :weight]
    attr_accessor :weight
    attr_reader   :type, :value, :created_at, :calais_ref_uri, :id
  
    def self.redis_datum_type_index_prefix
      "datum_index-datum_type->"
    end
    def redis_datum_type_index_key
      "#{self.class.redis_datum_type_index_prefix}#{type.name}"
    end
    # Calais Ref URIs are unique!
    def self.redis_calais_ref_uri_index_prefix
      "datum_index-calais_ref_uri->"
    end
    def redis_calais_ref_uri_index_key
      "#{self.class.redis_calais_ref_uri_index_prefix}#{calais_ref_uri}"
    end
    def redis_hash_key
      "datum->#{hash}"
    end
  
    def hash
      Digest::SHA1.hexdigest("#{value}+++#{type}+++#{calais_ref_uri}")
    end
    
    @@calais_ref_uri_map = {}
    @@datum_type_map = {}
  
    def initialize(configuration)
      @id = Convex.nid
      configuration = {
        :created_at => Time.now,
        :weight => 0.0,
        :type => DatumType::NoType
      }.merge(configuration)
      ATTRIBUTES.each { |attribute|
        instance_variable_set("@#{attribute}".to_sym, configuration[attribute])
      }
    end
  
    def inspect
      "(#{value}/#{type}/#{weight} #{hash}#{' #'+id.to_s if id})"
    end
    alias_method :to_s, :inspect
    alias_method :log_preamble, :inspect
    
    def remember
      remembered = Convex.db.hsetnx(redis_hash_key, :value, value)
      remembered &&= Convex.db.hsetnx(redis_hash_key, :type, type)
      remembered &&= Convex.db.hsetnx(redis_hash_key, :calais_ref_uri, calais_ref_uri)
      Convex.db.sadd(redis_datum_type_index_key, hash)
      Convex.db.setnx(redis_calais_ref_uri_index_key, hash)
      info "Remembered!" if remembered
      return self
    end
    
    def self.for_hash(hash)
      key = "datum->#{hash}"
      return Datum.new({
        :value => Convex.db.hget(key, :value),
        :type => Convex.db.hget(key, :type),
        :calais_ref_uri => Convex.db.hget(key, :calais_ref_uri)
      })
    end
    
    def self.[](param)
      if DatumType === param
        hashes = Convex.db.smembers "#{redis_datum_type_index_prefix}#{param.name}"
        hashes.collect { |hash| Datum.for_hash(hash) }
      elsif String === param && param[0..6] == 'http://'
        Datum.for_hash(Convex.db.get("#{redis_calais_ref_uri_index_prefix}#{param}"))
      elsif String === param
        Datum.for_hash(param)
      else
        nil
      end #if
    end
    
  end
end