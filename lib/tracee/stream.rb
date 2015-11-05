module Tracee
  
  class Stream
    attr_reader :target
      
    # @ target : IO | String | {<level name> => < level log file path >, ... } | {:cascade => < level log file path pattern >}
    # pattern example : "log/development.%{level}.log"
    def initialize(target)
      if target.is_a? Hash
        if pattern = target[:cascade]
          target = Tracee::Logger::LEVEL_NAMES.map {|name|
            [name, pattern % {level: name}]
          }.to_h
        else
          target = target.with_indifferent_access
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
      when IO, StringIO then @target.write msg
      when String then File.write @target, msg
      when Hash # cascade
        Tracee::Logger::LEVEL_NAMES[log_level..msg_level].each do |name|
          if path = @target[name]
            File.write path, msg
          end
        end
      end
    end

  end
    
end