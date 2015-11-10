# quiet_assets gem works only on thread-safe environment or on multithreaded one with only few assets.
# Known issue: https://github.com/evrone/quiet_assets/issues/40
# I'd fix it so that it would always reset log_level to that of Rails.application.config.log_level
# But such an approach will not allow to change log_level within runtime.
#
# Tracee deals with it in pretty straightforward manner. It just ignores whatever we do not care about.
module Tracee
  module Preprocessors
    class QuietAssets < Base
      
      def initialize(assets_paths=['assets'])
        @assets_paths_pattern = assets_paths * '|'
      end
    
      def call(msg_level, datetime, progname, msg, caller_slice=[])
        if msg =~ %r{^Started GET "/(#@assets_paths_pattern)/}
          halt!
        else
          msg
        end
      end

    end
  end
end