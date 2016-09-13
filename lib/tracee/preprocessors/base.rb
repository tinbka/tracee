module Tracee
  module Preprocessors
    class Base
      
      def call(msg_level, datetime, progname, msg, caller_slice=[])
        msg
      end
      
      def halt!
        throw :halt
      end
    
      def inspect
        '#<%s:0x00%x>'% [self.class.name, object_id << 1]
      end
      
    end
  end
end