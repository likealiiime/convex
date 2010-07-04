class NilEcho < NilClass
  def self.method_missing(symbol, *args);
    # TODO Check symbol to see if it ends with ?
    # if it does, return false
    return self
  end
  def self.to_i; 0; end
  def self.to_f; 0.0; end
  def self.to_s; ''; end
  def self.nil?; true; end
  
  def method_missing(symbol, *args); return self; end
  def to_i; 0; end
  def to_f; 0.0; end
  def to_s; ''; end
  def nil?; true; end
end

module Nokogiri
  module XML
    class NodeSet
      alias_method :dumb_slice, :[]
      def [](*parameters)
        result = dumb_slice(*parameters)
        result.nil? ? NilEcho : result
      end
    end
  end
end