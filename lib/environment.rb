module Convex
  class Environment
    class EnvironmentNotRecognizedError < ArgumentError; end
    class CannotBootIntoHeadlessModeError < RuntimeError; end
    
    MODES = [:development, :forgetful, :production, :headless]
    attr_reader :mode
    
    def initialize(mode)
      raise EnvironmentNotRecognizedError.new("#{mode} is not one of: #{MODES.join(', ')}") unless MODES.include? mode.to_sym
      @mode = mode.to_sym
      Postmark.api_key = "782667ec-e8dc-4c6d-a225-7432cc3451e4" if defined? Postmark
      
      # Set up paths
      library_paths = %w(lib lenses)
      if production?
        Convex.const_set('LOG_PATH',  '/var/log'.freeze)
        Convex.const_set('TMP_PATH',  '/tmp/convex'.freeze)
        Convex.const_set('PIDS_PATH', '/var/run'.freeze)
      else
        library_paths += %w(log tmp pids)
      end
      
      library_paths.each do |path|
        Convex.const_set("#{path.upcase}_PATH", File.join(ROOT_PATH, path).freeze)
        FileUtils.mkdir_p Convex.const_get("#{path.upcase}_PATH")
      end
        
      # Set up logging
      Convex::Logging.open_log_at File.join(Convex::LOG_PATH, "#{mode}.log")
    end
    
    def code; mode == :headless ? -1 : MODES.index(mode); end
    def production?; mode == :production; end
    def headless?; mode == :headless; end
    def development?; mode == :development || mode == :forgetful; end
    def forgetful?; mode == :forgetful; end
    def to_s; mode.to_s; end
  end
end