module Tracee
  module Preprocessors
    class Formatter < Base
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
        
        empty: ""
      }.freeze
      
      TEMPLATE_KEYS = %w{datetime level level_letter pid progname caller message}.freeze
      CALLER_KEYS = %W{path file line method}.freeze
          
      attr_reader :summary, :caller, :datetime, :level
      
      
      # available template keys : datetime, level, level_letter, pid, thread_id, progname, caller, message
      # available caller keys : path, file, line, method
      # params : {
      #    summary: <string containing available template keys as interpolation marks>,
      #    datetime: <format available to DateTime#strftime>,   # optional
      #    level: {<severity level name> => <label string>, ... },   # optional
      #    caller: <string containing available caller keys as interpolation marks>   # required if summary refers caller
      #  } 
      def initialize(params_or_key)
        if params_or_key.is_a? Symbol
          params = TEMPLATES[params_or_key]
        end
        if params.is_a? String
          params = {summary: params}
        end
        
        unless params.is_a? Hash
          raise TypeError, 'params must be a Hash or a reference to one of Tracee::Formatters::Template::TEMPLATES'
        end
        
        @summary, @caller, @datetime, @level = params.values_at(:summary, :caller, :datetime, :level).map &:freeze
        @references = TEMPLATE_KEYS.select {|key| @summary["%{#{key}}"]}.to_set
      end
      
      
      def call(msg_level, datetime, progname, msg, caller_slice=[])
        result = @summary.dup
        
        if @references.include? 'datetime'
          result.sub! '%{datetime}', datetime.strftime(@datetime || '%FT%T%Z')
        end
        
        if @references.include? 'level' or @references.include? 'level_letter'
          level = @level[msg_level] || msg_level
          result.sub! '%{level}', level
          result.sub! '%{level_letter}', level[0]
        end
        
        if @references.include? 'pid'
          result.sub! '%{pid}', Process.pid.to_s
        end
        
        if @references.include? 'thread_id'
          result.sub! '%{thread_id}', Thread.current.object_id
        end
        
        if @references.include? 'progname'
          result.sub! '%{progname}', progname
        end
        
        if @references.include? 'caller'
          caller_slice = caller_slice.reverse.map {|line|
            path, file, line, is_block, block_level, method = line.match(CALLER_RE)[1..-1]
            block_level ||= is_block && '1'
            method = "#{method} {#{block_level}}" if block_level
            @caller % {path: path, file: file, line: line, method: method}
          } * ' -> '
          result.sub! '%{caller}', caller_slice
        end
        
        if @references.include? 'message'
          if msg.nil?
            msg = "\b\b"
          elsif !msg.is_a?(String)
            msg = msg.inspect
          end
          result.sub! '%{message}', msg
        end
        
        return result + "\n"
      end
      
      
      def should_process_caller?
        @references.include? 'caller'
      end
      
      
      def inspect
        summary = @summary.dup
        if @datetime
          summary.sub!('%{datetime}', DateTime.parse('2000-10-20 11:22:33.123456789').strftime(@datetime))
        end
        if @level
          summary.sub!('%{level}', "{#{@level.values*', '}}")
          summary.sub!('%{level_letter}', "{#{@level.values.map {|w| w[0]}*', '}}")
        end
        if @caller
          summary.sub!('%{caller}', @caller.to_s)
        end
        %{#{to_s.chop} "#{summary}">}
      end
      
    end
  end
end