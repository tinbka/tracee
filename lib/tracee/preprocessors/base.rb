module Tracee
  module Preprocessors
    class Base
      
      def call(msg_level, datetime, progname, msg, caller_slice=[])
        msg
      end
      
      def halt!
        throw :halt
      end
      
    end
  end
end