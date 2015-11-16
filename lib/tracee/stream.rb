module Tracee
  
  class Stream
    attr_reader :target
    
    class TargetError < TypeError
      def initialize(message='A target must be IO | String | Hash{<level name> => <level log file path | IO>, ... } | Hash{:cascade => <level log file path pattern with "level" key>}', *) super end
    end
      
    # @ target : IO | String | {<level name> => < level log file path | IO >, ... } | {:cascade => < level log file path pattern >}
    # pattern example : "log/development.%{level}.log"
    def initialize(target)
      if target.is_a? Hash
        raise TargetError if target.values.any? {|val| !( val.is_a? String or val.is_a? IO or val.is_a? StringIO )}
        
        if pattern = target[:cascade]
          target = Tracee::Logger::LEVEL_NAMES.map {|name|
            [name, pattern % {level: name}]
          }.to_h
        else
          target = target.with_indifferent_access
        end
      
      else
        raise TargetError unless target.is_a? String or target.is_a? IO or target.is_a? StringIO
      end

      @target = target
    end
  
    # cascade principle:
    #
    # logger.log_level = :debug
    # logger.warn msg
    #   development.debug.log << msg
    #   development.info.log << msg
    #   development.warn.log << msg
    #   
    # logger.log_level = :warn
    # logger.error msg
    #   development.warn.log << msg
    #   development.error.log << msg
    def write(msg, msg_level=nil, log_level=nil)
      return if msg.nil?
      
      case @target
      when Hash # cascade
        Tracee::Logger::LEVEL_NAMES[log_level..msg_level].each do |name|
          if target = @target[name]
            io_write target, msg
          end
        end
      else
        io_write @target, msg
      end
    end
    
    alias << write
    
    private
    
    def io_write(target, msg)
      case target
      when IO, StringIO then target << msg
      when String then File.open(target, 'a') {|f| f << msg}
      end
    end

  end
  
  
  class IndifferentStream < Stream
    
    class TargetError < TypeError
      def initialize(message='A target must be an object implementing #<< method | Hash{<level name> => <such an object>, ... }', *) super end
    end
    
    # @ target : IO | String | {<level name> => < level log file path | IO >, ... } | {:cascade => < level log file path pattern >}
    # pattern example : "log/development.%{level}.log"
    def initialize(target)
      if target.is_a? Hash
        raise TargetError if target.values.any? {|val| !val.respond_to? :<<}
        
        target = target.with_indifferent_access
      else
        raise TargetError unless target.respond_to? :<<
      end

      @target = target
    end

    private
    
    def io_write(target, msg)
      target << msg
    end

  end
    
end