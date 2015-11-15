require 'tracee/stack/base_decorator'

module Tracee
  module Stack
    SCRIPT_LINES_MTIMES = {}
    
    # Rails' autoreload of code doesn't rewrite SCRIPT_LINES__,
    # to perform that automatically, Tracee::Stack.reload_script_lines should be turned on.
    # This mattr is left writable mostly for debug purposes.
    mattr_accessor :reload_script_lines
    self.reload_script_lines = true
    
    def self.readlines(file)
      if reload_script_lines
        if File.exists?(file)
          mtime = File.mtime(file)
          unless SCRIPT_LINES_MTIMES[file] and SCRIPT_LINES_MTIMES[file] >= mtime
            SCRIPT_LINES_MTIMES[file] = mtime
            SCRIPT_LINES__[file] = IO.readlines(file)
          end
          SCRIPT_LINES__[file]
        end
      else
        if lines = SCRIPT_LINES__[file]
          lines
        else
          if File.exists?(file)
            SCRIPT_LINES_MTIMES[file] = File.mtime(file)
            SCRIPT_LINES__[file] = IO.readlines(file)
          end
        end
      end
    end
    
    def self.readline(file, line)
      if lines = readlines(file)
        (lines[line.to_i - 1] || "<line #{line} is not found> ").chomp.green
      end
    end
  
  end
end