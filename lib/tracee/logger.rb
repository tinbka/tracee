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
    
    COLORED_LEVELS = {
      'debug' => 'DEBUG'.white,
      'info' => 'INFO'.light_cyan,
      'warn' => 'WARN'.light_magenta,
      'error' => 'ERROR'.light_yellow,
      'fatal' => 'FATAL'.light_red,
      'unknown' => 'UNKNOWN'.light_black
    }.freeze
    
    UPCASE_LEVELS = LEVEL_NAMES.map {|name| [name, name.upcase]}.to_h.freeze
    
    TEMPLATES = {
      tracee: {
        summary: "%{datetime} %{level} [%{caller}]: %{message}",
        datetime: "%T.%3N",
        level: COLORED_LEVELS,
        caller: "#{'%{file}:%{line}'.white} #{':%{method}'.light_red}"
      },
      
      plain: "%{message}",
      
      logger_formatter: {
        summary: "%{level_letter}, [%{datetime} #%{pid}] %{level} -- %{progname}: %{message}",
        datetime: "%FT%T.%6N",
        level: UPCASE_LEVELS
      }
    }.freeze
    
    TEMPLATE_KEYS = %w{datetime level level_letter pid progname caller message}.freeze
    CALLER_KEYS = %W{path file line method}.freeze
    
    CALLER_RE = \
      %r{^(.*?([^/\\]+?))#{	    # ( path ( file ) ) 
        }:(\d+)(?::in #{	      # :( line )[ :in
        }`(block (?:\((\d+) levels\) )?in )?(.+?)'#{   # `( [ block in ] closure )' ]
        })?$}
    
    
    attr_reader :log_level
    
    
    def initialize(stream: $stdout, streams: nil, formatters: [], template: :tracee, log_level: :info)
      streams = streams || Array.wrap(stream)
      @streams = streams.map {|item| Stream.new(each)}.freeze
      
      @formatters = []
      [method(:render_template), *formatters].each {|item| add_formatter item}
      
      set_template(template)
      
      log_level = log_level
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
    
    # available template keys : datetime, level, level_letter, pid, thread_id, progname, caller, message
    # available caller keys : path, file, line, method
    # template : {
    #    summary: <string containing available template keys as interpolation marks>,
    #    datetime: <format available to DateTime#strftime>,   # optional
    #    level: {<severity level name> => <label string>, ... },   # optional
    #    caller: <string containing available caller keys as interpolation marks>   # required if summary refers caller
    #  } 
    def set_template(string_or_key)
      if string_or_key.is_a? Symbol
        template = TEMPLATES[string_or_key]
      end
      if template.is_a? String
        template = {summary: template}
      end
      
      @template_references = TEMPLATE_KEYS.select do |key|
        template[:summary]["%{#{key}}"]
      end.to_set
      @template = template
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
    
    def log_level=(level)
      @log_level = level.is_a?(Integer) ? level : LEVELS.index(level.to_s.upcase)
    end
    
    
    def write(msg, progname, level, caller_slice)
      @formatters.each do |formatter|
        formatter.(msg, progname, level, caller_slice)
      end
      @streams.each do |stream|
        stream.write msg, level, log_level
      end
    end
    
    LEVELS.each_with_index do |level, index|
      const_set level, index
    
      level_name = level.downcase.to_sym
    
      define_method level_name do |msg_or_progname=nil, caller: 0, &block|
        return if log_level > index
        
        if @template_references.include? 'caller'
          caller = caller(1)
          if caller_at = opts.delete(:caller_at)
            if caller_at.is_a? Array
              caller_slice = caller_at.map! {|i| caller[i]}
            else
              caller_slice = caller[caller_at]
            end
          else
            caller_slice = caller[0]
          end
        end
        
        if @template_references.include? 'progname'
          if block
            msg = block.()
            progname = msg_or_progname
          else
            msg = msg_or_progname
          end
        else
          msg = block.() if block
        end
          
        write msg, progname, level_name, caller_slice
      end
      
      define_method :"#{level_name}?" do
        log_level <= index
      end
    end
    
    
    private
    
    def render_template(msg, progname, msg_level, caller_slice)
      result = @template[:summary].dup
      
      if @template_references.include? 'datetime'
        now = DateTime.now
        datetime = now.strftime(@template[:datetime] || '%FT%T%Z')
        result.sub! '%{datetime}', datetime
      end
      
      if @template_references.include? 'level' or @template_references.include? 'level_letter'
        level = @template[:level][msg_level]
        result.sub! '%{level}', level
        result.sub! '%{level_letter}', level[0]
      end
      
      if @template_references.include? 'pid'
        result.sub! '%{pid}', Process.pid
      end
      
      if @template_references.include? 'thread_id'
        result.sub! '%{thread_id}', Thread.current.object_id
      end
      
      if @template_references.include? 'progname'
        result.sub! '%{progname}', progname
      end
      
      if @template_references.include? 'caller'
        caller_slice = caller_slice.map {|line|
          path, file, line, is_block, block_level, method = line.match(CALLER_RE)[0..-1]
          block_level ||= is_block && '1'
          method = "#{method} {#{block_level}}" if block_level
          @template[:caller] % {path: path, file: file, line: line, method: method}
        } * ' -> '
        result.sub! '%{caller}', caller_slice
      end
      
      if @template_references.include? 'message'
        if msg.nil?
          msg = "\b\b"
        elsif !msg.is_a?(String)
          msg = msg.inspect
        end
        result.sub! '%{message}', msg
      end
      
      return result
    end
    
  end
  
end