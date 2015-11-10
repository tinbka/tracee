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
          
          # Well, metaprogamming is a game you can play together!
          # We do it so that Tracee::Logger would not have to care about an arity of corresponding #call or whatever.
          included do
            def self.extended(a_formatter_to_apply_tagging_on)
              if a_formatter_to_apply_tagging_on.is_a? Tracee::Formatters::Base
                a_formatter_to_apply_tagging_on.instance_variable_set\
                  :@original_call,
                  a_formatter_to_apply_tagging_on.class
                    .instance_method(:call)
                    .bind(a_formatter_to_apply_tagging_on)
                
                a_formatter_to_apply_tagging_on.class_eval do
                  def call(severity, timestamp, progname, msg, caller_slice=[])
                    @original_call.(severity, timestamp, progname, "#{tags_text}#{msg}", caller_slice)
                  end
                end
              end
            end
          end
          
        end
      end
          
        
    end
  end
end