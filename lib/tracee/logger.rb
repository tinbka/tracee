module Tracee
  
  class Logger
    LEVELS = [
      'DEBUG', # Low-level information for developers
      'INFO', # Generic (useful) information about system operation
      'WARN', ## A warning
      'ERROR', # A handleable error condition
      'FATAL', # An unhandleable error that results in a program crash
      'UNKNOWN' # An unknown message that should always be logged
    ].freeze
    LEVEL_NAMES = LEVELS.map(&:downcase).freeze
    
    
    attr_reader :log_level, :formatters, :streams
    
    
    def initialize(stream: $stdout, streams: nil, formatters: nil, template: :tracee, log_level: :info)
      @streams = []
      streams = streams || [stream]
      streams.each {|item| add_stream item}
      
      @formatters = []
      if formatters.nil?
        formatters = [Tracee::Formatters::Template]
        formatters[0].template = template
      end
      formatters.each {|item| add_formatter item}
      
      self.log_level = log_level
      read_log_level_from_env
    end
    
    
    def add_formatter(callable=nil, &block)
      if block
        @formatters << block
      elsif callable.respond_to? :call
        @formatters << callable
      else
        raise TypeError, 'A formatter must respond to #call'
      end
    end
    
    def add_stream(target)
      if target.is_a? Hash or target.is_a? String or target.is_a? IO
        @streams << Stream.new(target)
      else
        raise TypeError, 'A target must be IO | String | {<level name> => <level log file path>, ... } | {:cascade => <level log file path pattern with "level" key>}'
      end
    end
    
    private def read_log_level_from_env
      if ENV['LOG_LEVEL'] and LEVELS.include? ENV['LOG_LEVEL']
        self.log_level = ENV['LOG_LEVEL']
      elsif ENV['DEBUG'] || ENV['VERBOSE']
        self.log_level = 'DEBUG'
      elsif ENV['WARN'] || ENV['QUIET']
        self.log_level = 'WARN'
      elsif ENV['SILENT']
        self.log_level = 'ERROR'
      end
    end
    
    def log_level=(level)
      @log_level = level.is_a?(Integer) ? level : LEVELS.index(level.to_s.upcase)
    end
    
    
    def write(msg, progname, level, level_int, caller_slice)
      @formatters.each do |formatter|
        msg = formatter.(msg, progname, level, caller_slice)
      end
      @streams.each do |stream|
        stream.write msg, level_int, log_level
      end
      nil
    end
    
    LEVELS.each_with_index do |level, level_int|
      const_set level, level_int
    
      level_name = level.downcase
    
      class_eval <<-EOS, __FILE__, __LINE__
        def #{level_name}(msg_or_progname=nil, caller_at: 0, &block)
          return if @log_level > #{level_int}
          
          if @template_references.include? 'caller'
            caller = caller(1)
            if caller_at.is_a? Array
              caller_slice = caller_at.map! {|i| caller[i]}
            else
              caller_slice = Array.wrap caller[caller_at]
            end
          end
          
          if block
            msg = block.()
            progname = msg_or_progname
          else
            msg = msg_or_progname
          end
            
          write msg, progname, '#{level_name}', #{level_int}, caller_slice
        end
        
        def #{level_name}?
          @log_level <= #{level_int}
        end
      EOS
    end
    
  end
  
end