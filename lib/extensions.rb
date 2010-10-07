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
  def self.not_nil?; false; end
  
  def method_missing(symbol, *args); return self; end
  def to_i; 0; end
  def to_f; 0.0; end
  def to_s; ''; end
  def nil?; true; end
end

class NilClass
  def not_nil?; false; end
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

class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end
  
  def symbolize_keys!
    self.replace(self.symbolize_keys)
  end
end

class Array
  def sum; self.reduce(:+); end
  def **(b)
    raise ArgumentError.new("Cannot dot-multiply arrays of differing lengths") if self.length != b.length
    (0...self.length).to_a.collect { |i| self[i] * b[i] }.sum
  end
  def magnitude
    Math.sqrt(self ** self)
  end
  def square_magnitude
    self ** self
  end
end

unless Object.new.public_methods.include?('try') || Object.new.public_methods.include?(:try)
  class Object
    def try(method, *params)
      (params == [] ? self.send(method) : self.send(method, params)) rescue nil
    end
  end
end
  