module Convex
  class Environment
    class EnvironmentNotRecognizedError < ArgumentError; end
    class CannotBootIntoHeadlessModeError < RuntimeError; end
    
    MODES = [:development, :forgetful, :production, :headless]
    attr_reader :mode
    
    def initialize(mode)
      raise EnvironmentNotRecognizedError.new("#{mode} is not one of: #{MODES.join(', ')}") unless MODES.include? mode.to_sym
      @mode = mode.to_sym
      
      # Set up TMP_PATH because headless mode doesn't save temporary files
      if headless?
        Convex.const_set('TMP_PATH', '/dev/null'.freeze)
      else
        FileUtils.mkdir_p Convex.const_set('TMP_PATH',  '/tmp/convex'.freeze)
      end
      
      # Set up logging
      Convex.const_set('LOG_PATH', Convex::Environment::log_dir_for_mode(mode))
      Convex::Logging.open_log_at File.join(Convex::LOG_PATH, "#{mode}.log")
    end
    
    def self.log_dir_for_mode(mode = :forgetful)
      File.expand_path('~/.convex/log')
    end
    
    def code; mode == :headless ? -1 : MODES.index(mode); end
    def production?; mode == :production; end
    def headless?; mode == :headless; end
    def development?; mode == :development || mode == :forgetful; end
    def forgetful?; mode == :forgetful; end
    def to_s; mode.to_s; end
  end
end