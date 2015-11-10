module Tracee
  module Extensions
    module ActiveSupport
      
      module BacktraceCleaner
        extend ::ActiveSupport::Concern
        
        included do
          if defined? Rails
            Rails.backtrace_cleaner.add_silencer {|line| line =~ IGNORE_RE}
          end
          alias_method_chain :clean, :decorate
        end
          
        def clean_with_decorate(backtrace, kind=:silent)
          Stack::BaseDecorator.(clean_without_decorate(backtrace, kind))
        end
          
      end
      
      module TaggedLogging
        module Formatter
          extend ::ActiveSupport::Concern
          
          # Totally redefine, so that Tracee::Logger would not have to check #call arity on every write
          included do
            if self < Tracee::Formatters::Base
              def call(severity, timestamp, progname, msg, caller_slice=[])
                super(severity, timestamp, progname, "#{tags_text}#{msg}", caller_slice)
              end
            end
          end
          
        end
      end
          
        
    end
  end
end