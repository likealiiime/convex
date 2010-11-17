module Convex
  class Environment
    class EnvironmentNotRecognizedError < ArgumentError; end
    class CannotBootIntoHeadlessModeError < RuntimeError; end
    
    MODES = [:development, :forgetful, :production, :headless]
    attr_reader :mode
    
    def initialize(mode)
      raise EnvironmentNotRecognizedError.new("#{mode} is not one of: #{MODES.join(', ')}") unless MODES.include? mode.to_sym
      @mode = mode.to_sym
      
      # Set up paths
      local_paths = if production?
        Convex.const_set('LOG_PATH',  Convex::Environment.log_dir_for_mode(mode))
        FileUtils.mkdir_p Convex.const_set('TMP_PATH',  '/tmp/convex'.freeze)
        Convex.const_set('PIDS_PATH', '/var/run'.freeze)
        []
      elsif headless?
        Convex.const_set('LOG_PATH', Convex::Environment.log_dir_for_mode(mode))
        Convex.const_set('TMP_PATH', '/dev/null'.freeze)
        ['pids']
      else
        %w(log tmp pids)
      end
      
      local_paths.each do |path|
        Convex.const_set("#{path.upcase}_PATH", File.join(ROOT_PATH, path).freeze)
        FileUtils.mkdir_p Convex.const_get("#{path.upcase}_PATH")
      end
      # Set up logging
      Convex::Logging.open_log_at headless? ? NilEcho : File.join(Convex::LOG_PATH, "#{mode}.log")
    end
    
    def self.log_dir_for_mode(mode)
      mode ||= :forgetful
      case mode.to_sym
      when :production
        return '/var/log'
      when :headless
        return '/dev/null'
      else
        return 'log'
      end
    end
    
    def self.daemons_dir_hash_for_argv
      daemons_dir_hash_for_mode ARGV.first
    end
    
    def self.daemons_dir_hash_for_mode(mode)
      mode ||= :forgetful
      if mode.to_sym == :production || mode.to_sym == :headless
        return { :dir_mode => :normal, :dir => log_dir_for_mode(mode) }
      else
        return { :dir_mode => :script, :dir => log_dir_for_mode(mode) }
      end
    end
    
    def code; mode == :headless ? -1 : MODES.index(mode); end
    def production?; mode == :production; end
    def headless?; mode == :headless; end
    def development?; mode == :development || mode == :forgetful; end
    def forgetful?; mode == :forgetful; end
    def to_s; mode.to_s; end
  end
end