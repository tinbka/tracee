module Tracee
  
  class Stream
      
    # @ target : IO | String | {<level name> => < level log file path >, ... } | {:cascade => < level log file path pattern >}
    # pattern example : "log/development.%{level}.log"
    def initialize(target)
      if target.is_a? Hash
        if pattern = target[:cascade]
          target = Tracee::Logger::LEVEL_NAMES.each {|name|
            [name, pattern % {level: name}]
          }.to_h
        else
          target = target.stringify_keys
        end
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
    def write(msg, msg_level, log_level)
      case @target
      when IO then @target.write msg
      when String then File.write @target, msg
      when Hash # cascade
        Tracee::Logger::LEVEL_NAMES[log_level..msg_level].each do |name|
          File.write @target[name], msg
        end
      end
    end

  end
    
end