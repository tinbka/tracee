module Tracee
  module Extensions
    module BetterErrors
      module Middleware
        extend ::ActiveSupport::Concern
        
        included do
          alias_method_chain :log_exception, :decorate
        end
        
        def log_exception_with_decorate
          return unless BetterErrors.logger

          message = "\n#{@error_page.exception.class} - #{@error_page.exception.message}:\n"
          
          frames = @error_page.backtrace_frames # original definition
          frames = frames.map(&:to_s).reject {|line| line =~ Tracee::IGNORE_RE}
          frames = Tracee::Stack::BaseDecorator.(frames)
          frames.each do |frame|
            message << "  #{frame}\n"
          end

          BetterErrors.logger.fatal message
        end
        
      end
    end
  end
end