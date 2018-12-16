module Tracee
  module Extensions
    module BetterErrors
      module Middleware
        extend ::ActiveSupport::Concern
        
        included do
          def log_exception
            return unless logger = ::BetterErrors.logger

            message = "\n#{@error_page.exception_type} - #{@error_page.exception_message}:"

            logger.fatal message
            
            frames = @error_page.backtrace_frames # original definition
            frames = frames.map(&:to_s)
            if !$DEBUG and Tracee.better_errors_quiet_backtraces
              frames = frames.reject {|line| line =~ IGNORE_RE}
            end
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
end