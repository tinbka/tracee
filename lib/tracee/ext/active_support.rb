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
        
    end
  end
end