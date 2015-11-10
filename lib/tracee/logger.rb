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
    
    
    attr_reader :level, :preprocessors, :formatter, :streams
    
    
    def initialize(stream: $stdout, streams: nil, formatter: {:template => :tracee}, preprocessors: [], level: :info)
      @streams = []
      streams ||= [stream]
      streams.each {|item| add_stream item}
      
      if formatter.is_a? Hash
        # `formatter=' can't accept *array
        set_formatter *formatter.to_a.flatten
      else
        self.formatter = formatter
      end
      
      @preprocessors = []
      preprocessors.each {|item|
        if item.is_a? Hash
          add_preprocessor *item.to_a.flatten
        else
          add_preprocessor item
        end
      }
      
      self.level = level
      read_log_level_from_env
    end
    
    
    def add_preprocessor(callable_or_symbol=nil, *preprocessor_params)
      if callable_or_symbol.is_a? Symbol
        @preprocessors << Tracee::Preprocessors.const_get(callable_or_symbol.to_s.camelize).new(*preprocessor_params)
      elsif callable_or_symbol.respond_to? :call
        @preprocessors << callable_or_symbol
      else
        raise TypeError, 'A preprocessor must respond to #call'
      end
    end
    
    def set_formatter(callable_or_symbol=nil, *formatter_params)
      if callable_or_symbol.is_a? Symbol
        @formatter = Tracee::Formatters.const_get(callable_or_symbol.to_s.camelize).new(*formatter_params)
      elsif callable_or_symbol.respond_to? :call
        @formatters = callable_or_symbol
      else
        raise TypeError, 'A formatter must respond to #call'
      end
    end
    alias formatter= set_formatter
    
    delegate :should_process_caller?, to: :formatter
    
    def add_stream(target)
      case target
      when Hash, String, IO, StringIO
        @streams << Stream.new(target)
      else
        raise TypeError, 'A target must be IO | String | {<level name> => <level log file path>, ... } | {:cascade => <level log file path pattern with "level" key>}'
      end
    end
    
    
    def level=(level)
      @level = level.is_a?(Integer) ? level : LEVELS.index(level.to_s.upcase)
    end
    
    alias log_level= level=
    alias log_level level
    
    
    def write(msg, progname, level, level_int, caller_slice=[])
      now = DateTime.now
      
      catch :halt do
        @preprocessors.each do |preprocessor|
          msg = preprocessor.(level, now, progname, msg, caller_slice)
        end
        
        msg = @formatter.(level, now, progname, msg, caller_slice)
        
        @streams.each do |stream|
          stream.write msg, level_int, log_level
        end
      end
      nil
    end
    
    LEVELS.each_with_index do |level, level_int|
      const_set level, level_int
    
      level_name = level.downcase
    
      class_eval <<-EOS, __FILE__, __LINE__+1
        def #{level_name}(*args, &block)
          return if @level > #{level_int}
          
          if block
            msg = block.()
            if args[0].is_a? Hash
              caller_at = args[0][:caller_at] || 0
            else
              progname = args[0].to_s
            end
          else
            msg = args[0]
          end
          
          if should_process_caller?
            caller = caller(1)
            
            caller_at ||= (args[1] || {})[:caller_at] || 0
            if caller_at.is_a? Array
              caller_slice = caller_at.map! {|i| caller[i]}
            else
              caller_slice = [*caller[caller_at]]
            end
          end
            
          write msg, progname, '#{level_name}', #{level_int}, caller_slice
        end
        
        def #{level_name}?
          @level <= #{level_int}
        end
      EOS
    end
    
    alias <= debug
    alias << info
    alias < warn
    
    
    def benchmark(times: 1, &block)
      before_proc = Time.now
      (times - 1).times {yield}
      result = yield
      now = Time.now
      tick "[#{highlight_time_diff((now - before_proc)*1000/times)}ms each] #{result}", caller_offset: 1
    end
    
    def tick(msg='', caller_offset: 0)
      now = Time.now
      if prev = Thread.current[:tracee_checkpoint]
        info "[tick +#{highlight_time_diff(now - prev)}] #{msg}", caller_at: caller_offset+1
      else
        info "[tick] #{msg}", caller_at: caller_offset+1
      end
      Thread.current[:tracee_checkpoint] = now
    end
    
    def tick!(msg='', caller_offset: 0)
      Thread.current[:tracee_checkpoint] = nil
      tick msg, caller_offset: caller_offset+1
    end
    
    
    private
    
    def highlight_time_diff(diff)
      diff.round(6).to_s.sub(/(\d+)\.(\d{0,3})(\d*)$/) {|m| "#$1.".light_white + $2.white + $3.light_black}
    end
    
    
    def read_log_level_from_env
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
    
  end
  
end