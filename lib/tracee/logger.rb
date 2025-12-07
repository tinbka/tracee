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

    include Tracee::Benchmarkable


    attr_reader :level, :preprocessors, :formatter, :streams


    def initialize(stream: $stdout, streams: nil, formatter: {:default => :plain}, preprocessors: [], level: :info, default: false)
      @streams = []
      streams ||= [stream]
      streams.each {|item| add_stream item}
      # Hack for deduplication of console loggers in Rails 7.1
      @logdev = @streams[0]

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

      if default
        if Tracee.default_logger
          warn "Overwriting default logger #{Tracee.default_logger.inspect}\nwith the new one: #{inspect}"
        end
        Tracee.default_logger = self
      end
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
        @formatter = Tracee::Preprocessors.const_get(callable_or_symbol.to_s.camelize.sub('Default', 'Formatter')).new(*formatter_params)
      elsif callable_or_symbol.respond_to? :call
        @formatters = callable_or_symbol
      else
        raise TypeError, 'A formatter must respond to #call'
      end
    end
    alias formatter= set_formatter

    def should_process_caller?
      formatter.respond_to? :should_process_caller? and formatter.should_process_caller?
    end

    def add_stream(target_or_stream)
      if target_or_stream.is_a? Tracee::Stream
        @streams << target_or_stream
      else
        @streams << Stream.new(target_or_stream)
      end
    end

    def level=(level)
      Thread.current["tracee_#{__id__}_level"] = @level = norm_level(level)
    end

    def local_level=(level)
      Thread.current["tracee_#{__id__}_level"] = norm_level(level)
    end

    def local_level
      Thread.current["tracee_#{__id__}_level"] ||= @level
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
          return if local_level > #{level_int}

          unless args[1].nil? or args[1].is_a?(Hash)
            raise TypeError, "\#{self.class.name}#\#{__callee__}'s second argument if given, is expected to be Hash. \#{args[1].class.name} is given."
          end

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
          # Although in all other cases it works like `print`, `nil` logged as "nil" for visibility
          msg = 'nil' if msg.nil?

          if should_process_caller?
            caller = caller(1)

            caller_at ||= (args[1] || {})[:caller_at] || 0
            if caller_at.is_a? Array
              caller_slice = caller_at.map! {|i| caller[i]}
            else
              caller_slice = [caller[caller_at]]
            end
          else
            caller_slice = []
          end

          write msg, progname, '#{level_name}', #{level_int}, caller_slice.flatten
        end

        def #{level_name}!
          self.level = #{level_int}
        end

        def #{level_name}?
          @level <= #{level_int}
        end
      EOS
    end

    alias <= debug
    alias << info
    alias < warn

    def add(*args)
      @streams.each do |stream|
        next if stream.target == STDOUT
        stream.write args[2], args[0], log_level
      end
    end


    def silence(temporary_level=:error)
      begin
        old_local_level = local_level
        self.local_level = temporary_level

        yield self
      ensure
        self.local_level = old_local_level
      end
    end

    def default?
      Tracee.default_logger.eql? self
    end

    def default=(boolean)
      if boolean
        Tracee.default_logger = self
      elsif default?
        Tracee.default_logger = nil
      end
    end

    private

    def norm_level(level)
      level.is_a?(Integer) ? level : LEVELS.index(level.to_s.upcase)
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
