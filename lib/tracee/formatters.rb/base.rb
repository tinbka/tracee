module Tracee
  module Formatters
    class Base
      
      def call(msg, progname, msg_level, caller_slice)
        msg
      end
      
    end
  end
end