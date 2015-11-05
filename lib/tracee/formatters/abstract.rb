module Tracee
  module Formatters
    class Abstract
      
      def call(msg, progname, msg_level, caller_slice)
        msg
      end
      
      def should_process_caller?
        false
      end
      
    end
  end
end