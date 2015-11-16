begin
  require 'rails'

  module Tracee
    class Engine < Rails::Engine

      initializer "tracee.decorate_stack" do |app|
        if defined? ::BetterErrors
          Tracee.decorate_better_errors_stack
        else
          Tracee.decorate_active_support_stack
        end
      end
        
    end
  end
rescue LoadError
end