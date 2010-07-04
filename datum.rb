class Datum
  ATTRIBUTES = [:value, :created_at, :calais_ref_uri, :type, :weight]
  attr_accessor :weight, :type
  attr_reader   :value, :created_at, :calais_ref_uri
  
  @@calais_ref_uri_map = {}
  @@datum_type_map = {}
  
  def initialize(configuration)
    configuration = {
      :created_at => Time.now,
      :weight => 0.0,
      :type => DatumType::NoType
    }.merge(configuration)
    ATTRIBUTES.each { |attribute|
      instance_variable_set("@#{attribute}".to_sym, configuration[attribute])
    }
    @@calais_ref_uri_map[calais_ref_uri] = self unless calais_ref_uri.nil?
    @@datum_type_map[type.name] ||= []
    @@datum_type_map[type.name] << self
  end
  
  def inspect
    "(#{value}/#{type} #{weight})"
  end
  
  def self.[](uri_or_type)
    if DatumType === uri_or_type
      @@datum_type_map[uri_or_type.name]
    else
      @@calais_ref_uri_map[uri_or_type]
    end
  end
  
  def self.datum_type_map; @@datum_type_map; end
  def self.calais_ref_uri_map; @@calais_ref_uri_map; end
end