module Tracee
  module Extensions
    module Exception
      
      def self.prepended(exc_class)
        exc_class.send :class_attribute, :trace_decorator
      end
      
      ## Gotcha:
      # If you also set (e.g. in irbrc file) 
      #
      #   SCRIPT_LINES__['(irb)'] = []
      #   module Readline
      #     alias :orig_readline :readline
      #     def readline(*args)
      #       ln = orig_readline(*args)
      #       SCRIPT_LINES__['(irb)'] << "#{ln}\n"
      #       ln
      #     end
      #   end
      #
      # it will be possible to fetch lines entered in IRB
      # else format_trace would only read ordinary require'd files
      ##
      if RUBY_VERSION > '2.1'
        
        def set_backtrace(trace)
          if decorator = self.class.trace_decorator
            if trace.is_a? Thread::Backtrace
              return trace
            else
              trace = decorator.(trace)
            end
          end
          
          super(trace)
        end
        
      else
        
        def set_backtrace(trace)
          if decorator = self.class.trace_decorator
            trace = decorator.(trace)
          end
          
          super(trace)
        end
        
      end
      
      ## Use case: 
      # We have some method that we don't want to crash application in production but want to have this crash potential been logged
      #
      # def unsured_method
      #   ... some crashable calls ...
      # rescue PotentialException
      #   $!.log
      # end
      ##
      def log
        Rails.logger.error [
              "The exception has been handled: #{self.class} — #{message.force_encoding('UTF-8')}:",
              *Rails.backtrace_cleaner.clean(backtrace)
            ]*"\n"
      end
          
    end
  end
end