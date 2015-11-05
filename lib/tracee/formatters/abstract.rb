module Tracee
  module Formatters
    class Abstract
      
      def call(msg_level, datetime, progname, msg, caller_slice=[])
        msg
      end
      
      def should_process_caller?
        false
      end
      
    end
  end
end