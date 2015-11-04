module Tracee
  module Formatters
    class Template < Base
      COLORED_LEVELS = {
        'debug' => 'DEBUG'.white,
        'info' => 'INFO'.light_cyan,
        'warn' => 'WARN'.light_magenta,
        'error' => 'ERROR'.light_yellow,
        'fatal' => 'FATAL'.light_red,
        'unknown' => 'UNKNOWN'.light_black
      }.freeze
      
      UPCASE_LEVELS = Tracee::Logger::LEVEL_NAMES.map {|name| [name, name.upcase]}.to_h.freeze
      
      TEMPLATES = {
        tracee: {
          summary: "%{datetime} %{level} [%{caller}]: %{message}",
          datetime: "%T.%3N",
          level: COLORED_LEVELS,
          caller: "#{'%{file}:%{line}'.white} #{':%{method}'.light_red}"
        },
        
        logger_formatter: {
          summary: "%{level_letter}, [%{datetime} #%{pid}] %{level} -- %{progname}: %{message}",
          datetime: "%FT%T.%6N",
          level: UPCASE_LEVELS
        },
        
        plain: "%{message}",
        
        none: ""
      }.freeze
      
      TEMPLATE_KEYS = %w{datetime level level_letter pid progname caller message}.freeze
      CALLER_KEYS = %W{path file line method}.freeze
      
      CALLER_RE = \
        %r{^(.*?([^/\\]+?))#{	    # ( path ( file ) ) 
          }:(\d+)(?::in #{	      # :( line )[ :in
          }`(block (?:\((\d+) levels\) )?in )?(.+?)'#{   # `( [ block in ] closure )' ]
          })?$}
      
      # available template keys : datetime, level, level_letter, pid, thread_id, progname, caller, message
      # available caller keys : path, file, line, method
      # template : {
      #    summary: <string containing available template keys as interpolation marks>,
      #    datetime: <format available to DateTime#strftime>,   # optional
      #    level: {<severity level name> => <label string>, ... },   # optional
      #    caller: <string containing available caller keys as interpolation marks>   # required if summary refers caller
      #  } 
      def template=(string_or_key)
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
      
      
      def call(msg, progname, msg_level, caller_slice)
        result = @template[:summary].dup
        
        if @template_references.include? 'datetime'
          now = DateTime.now
          datetime = now.strftime(@template[:datetime] || '%FT%T%Z')
          result.sub! '%{datetime}', datetime
        end
        
        if @template_references.include? 'level' or @template_references.include? 'level_letter'
          level = @template[:level][msg_level] || msg_level
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
            path, file, line, is_block, block_level, method = line.match(CALLER_RE)[1..-1]
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
        
        return result + "\n"
      end
      
    end
  end
end