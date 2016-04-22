module Tracee
  module Extensions
    module BetterErrors
      module Middleware
        extend ::ActiveSupport::Concern
        
        included do
          alias_method_chain :log_exception, :decorate
        end
        
        def log_exception_with_decorate
          return unless logger = ::BetterErrors.logger

          message = "\n#{@error_page.exception.class} - #{@error_page.exception.message}:"

          logger.fatal message
          
          frames = @error_page.backtrace_frames # original definition
          frames = frames.map(&:to_s).reject {|line| line =~ IGNORE_RE}
          frames = Stack::BaseDecorator.(frames, paint_code_line: :greenish)
          frames.each do |frame|
            if frame =~ /^[-\w]+ \(\d+\.[\w\.]+\) /
              logger.debug "  #{frame}"
            else
              logger.fatal "  #{frame}"
            end
          end
        end
        
      end
    end
  end
end