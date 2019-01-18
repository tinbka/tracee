# When you working with IRB/Pry/Ripl it should be defined in the according rc-file so that all loaded ruby files could be cached into it.
unless defined? SCRIPT_LINES__
  SCRIPT_LINES__ = {}
end

require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/date_time'
require 'active_support/tagged_logging'

require 'colorize'

require 'tracee/version'
require 'tracee/benchmarkable'
require 'tracee/logger'
require 'tracee/preprocessors/base'
require 'tracee/preprocessors/formatter'
require 'tracee/preprocessors/quiet_assets'
require 'tracee/preprocessors/colorize'
require 'tracee/stream'
require 'tracee/stack'
require 'tracee/ext/object'
require 'tracee/ext/exception'
require 'tracee/ext/active_support'
require 'tracee/ext/better_errors'
require 'tracee/engine'

module Tracee
  CALLER_RE = \
    %r{^(?<path>.*?(?<file>[^/\\]+?))#{ # ( path ( file ) ) 
      }:(?<line>\d+)(?::in #{ # :( line )[ :in
      }`(?<is_block>block (?:\((?<block_level>\d+) levels\) )?in )?(?<method>.+?)'#{ # `( [ block in ] closure )' ]
      })?$}
      
  IGNORE_RE = \
    %r{/irb(/|\.rb$)#{ # irb internals
      }|^[\w\-]+ \([\d\.]+\) #{ # rails-formatted gem paths
      }|/ruby-\d.\d.\d(@[^/]+)?/gems/#{ # standard rvm gem paths
      }|lib/active_support/dependencies.rb$#{ # everywhere-proxy
      }|^-e$#{ # ruby -e oneliner
      }|^(script|bin)/#{ # other common entry points
      }|/gems/bundler-\d|/ruby-\d.\d.\d(@[^/]+)?/bin/#{ # bundle console
      }|bin/rails$|lib/rails/commands(/|\.rb$)#{ # rails console
      }|lib/spring/#{ # spring middleware
      }|/rubygems/core_ext/kernel_require.rb#{ # `require' override
      }}
      
  # Disable gem-related lines in BetterErrors exception backtrace log output
  mattr_accessor :better_errors_quiet_backtraces
  self.better_errors_quiet_backtraces = true
      
  # Default logger to respond to Object#__log__
  mattr_accessor :default_logger
      
  # In order to use Tracee's trace decorator with BetterErrors, Tracee must be loaded prior to BetterErrros.
  if defined? ::BetterErrors::ExceptionExtension
    # BetterErrors was loaded and BetterErrors::ExceptionExtension was prepended to Exception.
    # There is no way to seamlessly use another extension in between them
    # without side-effects, so we just skip extending.
  else
    # BetterErrors has not yet been loaded or will not be loaded at all.
    # Just insert the extension before Exception.
    ::Exception.prepend Tracee::Extensions::Exception
  end
  ::Exception.send :class_attribute, :trace_decorator
  
  
  # Doesn't work with Rails 5+
  module ::ActiveSupport::TaggedLogging::Formatter
    include Tracee::Extensions::ActiveSupport::TaggedLogging::Formatter
  end
  
  
  # Use `Tracee.decorate_stack_everywhere` only within a console, because it significantly slowdown rails middleware.
  # So better put it into .irbrc or similar.
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
      ActiveSupport::BacktraceCleaner.prepend Tracee::Extensions::ActiveSupport::BacktraceCleaner
    end
    
    def decorate_stack_everywhere
      decorate_exceptions_stack
      decorate_better_errors_stack(true)
      decorate_active_support_stack
    end
  
  end
  
  Logger.new default: true
end