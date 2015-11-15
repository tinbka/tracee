# When you working with IRB/Pry/Ripl It should be defined in according rc-file for all loaded ruby files to be cached into.
unless defined? SCRIPT_LINES__
  SCRIPT_LINES__ = {}
end

require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/class/attribute'
require 'active_support/tagged_logging'

require 'colorize'

require 'tracee/version'
require 'tracee/benchmarkable'
require 'tracee/logger'
require 'tracee/formatters/base'
require 'tracee/formatters/template'
require 'tracee/preprocessors/base'
require 'tracee/preprocessors/quiet_assets'
require 'tracee/stream'
require 'tracee/stack'
require 'tracee/ext/exception'
require 'tracee/ext/active_support'
require 'tracee/ext/better_errors'

module Tracee
  CALLER_RE = \
    %r{^(?<path>.*?(?<file>[^/\\]+?))#{ # ( path ( file ) ) 
      }:(?<line>\d+)(?::in #{ # :( line )[ :in
      }`(?<is_block>block (?:\((?<block_level>\d+) levels\) )?in )?(?<method>.+?)'#{ # `( [ block in ] closure )' ]
      })?$}
      
  IGNORE_RE = \
    %r{/irb(/|\.rb$)#{ # irb internals
      }|lib/active_support/dependencies.rb$#{ # everywhere-proxy
      }|^-e:#{ # ruby -e oneliner
      }|^(script|bin)/#{ # other common entry points
      }|/gems/bundler-\d|ruby-\d.\d.\d(@[^/]+)?/bin/#{ # bundle console
      }|lib/rails/commands(/|\.rb$)#{ # rails console
      }}
      
      
  class ::Exception
    include Tracee::Extensions::Exception
  end
  
  module ::ActiveSupport::TaggedLogging::Formatter
    include Tracee::Extensions::ActiveSupport::TaggedLogging::Formatter
  end
  
  ## Rails usage
  # Add to initializers:
  #
  # unless Rails.env.production?
  #   Tracee.decorate_better_errors_stack # if you're using better_errors
  #   Tracee.decorate_active_support_stack # otherwise
  # end
  #
  # Because these decorations may slightly slowdown an application, they're not run automatically.
  #
  # Use `Tracee.decorate_stack_everywhere` only within a console, because it significantly slowdown rails middleware.
  # So better put it into .irbrc or similar.
  ##
  class << self
    
    def decorate_exceptions_stack
      Exception.trace_decorator = Stack::BaseDecorator
      
      # These would extremely slowdown or stop runtime
      [SystemStackError, NoMemoryError, NameError, defined?(IRB::Abort) && IRB::Abort].compact.each do |klass|
        klass.trace_decorator = nil
      end
      
      # But this NameError's subclass would not
      NoMethodError.trace_decorator = Exception.trace_decorator
    end
    
    def decorate_better_errors_stack(from_decorate_everywhere=false)
      if defined? BetterErrors
        BetterErrors::Middleware.class_eval do
          include Tracee::Extensions::BetterErrors::Middleware
        end
      elsif !from_decorate_everywhere
        warn "Tracee.decorate_better_errors_stack was ignored, because BetterErrors hadn't been defined."
      end
    end
    
    def decorate_active_support_stack
      ActiveSupport::BacktraceCleaner.class_eval do
        include Tracee::Extensions::ActiveSupport::BacktraceCleaner
      end
    end
    
    def decorate_stack_everywhere
      decorate_exceptions_stack
      decorate_better_errors_stack(true)
      decorate_active_support_stack
    end
  
  end
  
  
  $log ||= Logger.new
end